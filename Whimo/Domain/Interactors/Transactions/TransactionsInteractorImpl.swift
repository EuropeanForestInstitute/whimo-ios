//
//  TransactionsInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.05.2025.
//
//  Copyright (c) 2025 EFI https://efi.int/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import struct CoreLocation.CLLocationCoordinate2D
import RestClient
import Utility

final class TransactionsInteractorImpl: TransactionsInteractor {
    // MARK: - Error
    enum Error: LocalizedError {
        case recipientNotSelected

        var errorDescription: String? {
            switch self {
                case .recipientNotSelected:
                    "Please select recipient."
            }
        }
    }

    @MainActor private var statusSubmissions: [String: BusinessDataContext.Generation] = [:]

    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let appState: AppState
    private let transactionsRemoteRepository: TransactionsRemoteRepository
    private let transactionsCachingRepository: TransactionsCachingRepository
    private let transactionsLocalRepository: TransactionsLocalRepository
    private let creationSeasonInteractor: CreationSeasonInteractor

    // MARK: - Init
    init(
        appState: AppState,
        transactionsRemoteRepository: TransactionsRemoteRepository,
        transactionsCachingRepository: TransactionsCachingRepository,
        transactionsLocalRepository: TransactionsLocalRepository,
        creationSeasonInteractor: CreationSeasonInteractor,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.appState = appState
        self.transactionsRemoteRepository = transactionsRemoteRepository
        self.transactionsCachingRepository = transactionsCachingRepository
        self.transactionsLocalRepository = transactionsLocalRepository
        self.creationSeasonInteractor = creationSeasonInteractor
    }

    // MARK: - TransactionsInteractor
    func fetchSuppliersTransactions(
        commodityGroupId: String,
        buyerId: String,
        createdAtTo: String?,
        oldPagination: TransactionsPagination?,
        refresh: Bool
    ) async throws -> (list: IdentifiedArrayOf<SupplierTransactionModel>, pagination: TransactionsPagination) {
        try await businessDataContext.withCurrentGeneration {
            let pagination: TransactionsPagination

            if !refresh, let oldPagination {
                pagination = .init(
                    searchData: .byBuyer(
                        .init(
                            commodityGroupId: commodityGroupId,
                            buyerId: buyerId
                        ),
                        createdAtTo: createdAtTo
                    ),
                    pageData: .init(
                        page: oldPagination.pageData.page + 1,
                        pageSize: oldPagination.pageData.pageSize
                    )
                )
            } else {
                pagination = .supplierInitial(
                    buyerData: .init(
                        commodityGroupId: commodityGroupId,
                        buyerId: buyerId
                    ),
                    createdAtTo: createdAtTo
                )
            }

            let responseData = try await transactionsCachingRepository.fetchSupplierTransactions(with: pagination)
            let updatedPageData: PaginationRequest = .init(
                page: responseData.pagination.nextPage == nil ? oldPagination?.pageData.page ?? PaginationRequest.initial.page : pagination.pageData.page,
                pageSize: pagination.pageData.pageSize
            )
            var updatedPagination: TransactionsPagination = .init(
                searchData: .byBuyer(pagination.searchData.buyerData),
                pageData: updatedPageData
            )
            updatedPagination.nextPage = responseData.pagination.nextPage

            return (responseData.list, updatedPagination)
        }
    }

    @discardableResult
    func fetchTransaction(by id: String) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            let transaction = try await transactionsCachingRepository.fetchTransaction(by: id)

            try await businessDataContext.commitState {
                appState.transactions.dispatch { state in
                    state.updateList(with: transaction)
                }
            }

            return transaction
        }
    }

    func refreshTransactionDetails(by id: String) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            try await transactionsRemoteRepository.fetchTransaction(by: id)
        }
    }

    func cacheTransactionDetails(_ transaction: TransactionModel, replacing previous: TransactionModel) async throws {
        try await businessDataContext.withCurrentGeneration {
            try businessDataContext.capture().check()
            try await transactionsLocalRepository.saveRefreshedDetails(transaction, replacing: previous)
        }
    }

    func createProducerTransaction(
        farmLocation: FarmLocation?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        isBuyingFromFarmer: Bool,
        transactionCoordinates: CLLocationCoordinate2D?,
        inviteRecipient: TransactionType.Recipient?
    ) async throws {
        try await businessDataContext.withProtectedWork {
            let catalogue = try await creationSeasonInteractor.seasons(commodityId: commodityType.id)
            let activeSeasons = catalogue.values.filter { $0.status == .active && !$0.id.isEmpty }
            guard activeSeasons.count == 1, let season = activeSeasons.first else { throw CreationSeasonError.catalogueRequired }

            try businessDataContext.capture().check()
            let locationData = convertFarmLocation(farmLocation)

            var requestRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?
            if inviteRecipient?.email.isEmpty == false,
               let email = inviteRecipient?.email {
                requestRecipient = .email(email)
            } else if inviteRecipient?.phone.isEmpty == false,
                      let phone = inviteRecipient?.phone {
                requestRecipient = .phone(phone)
            }

            let transaction = try await transactionsCachingRepository.createProducerTransaction(
                commodityId: commodityType.id,
                location: locationData.location,
                uploadFile: locationData.uploadFile,
                farmCoordinates: locationData.farmCoordinates,
                transactionCoordinates: transactionCoordinates,
                volume: volume,
                inviteRecipient: requestRecipient,
                isBuyingFromFarmer: isBuyingFromFarmer,
                season: season
            )

            try await businessDataContext.commitState {
                appState.transactions.dispatch { $0.updateList(with: transaction) }
            }
        }
    }

    func createDownstreamTransaction(
        farmLocation: FarmLocation?,
        transactionCoordinates: CLLocationCoordinate2D?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        action: TransactionModel.Action,
        recipient: TransactionType.Recipient,
        seasonSelection: CreationSeason?
    ) async throws {
        try await businessDataContext.withProtectedWork {
            let season = try await creationSeasonInteractor.validate(seasonSelection, commodityId: commodityType.id)
            if action == .sell {
                try await validateSale(volume: volume, commodityId: commodityType.id, season: season)
            }
            try businessDataContext.capture().check()
            let locationData = convertFarmLocation(farmLocation)

            let requestRecipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
            if !recipient.recipientID.isEmpty {
                requestRecipient = .name(recipient.recipientID)
            } else if !recipient.email.isEmpty {
                requestRecipient = .email(recipient.email)
            } else if !recipient.phone.isEmpty {
                requestRecipient = .phone(recipient.phone)
            } else {
                throw Error.recipientNotSelected
            }

            let transaction = try await transactionsCachingRepository.createDownstreamTransaction(
                commodityId: commodityType.id,
                location: locationData.location,
                uploadFile: locationData.uploadFile,
                farmCoordinates: locationData.farmCoordinates,
                transactionCoordinates: transactionCoordinates,
                volume: volume,
                action: action,
                recipient: requestRecipient,
                season: season
            )

            try await businessDataContext.commitState {
                appState.transactions.dispatch { $0.updateList(with: transaction) }
            }
        }
    }

    @MainActor
    func updateTransaction(_ transaction: TransactionModel, status: TransactionModel.StatusChange) async throws -> TransactionModel.StatusOutcome {
        try await businessDataContext.withProtectedWork {
            let generation = try businessDataContext.capture()
            guard statusSubmissions[transaction.id] !== generation else { throw TransactionModel.StatusChangeError.alreadySubmitting }

            statusSubmissions[transaction.id] = generation
            defer {
                if statusSubmissions[transaction.id] === generation { statusSubmissions[transaction.id] = nil }
            }
            guard transaction.status == .pending, transaction.persistingData.state == .sync else {
                throw TransactionModel.StatusChangeError.invalidResponse
            }
            var outcome = try await transactionsRemoteRepository.updateTransaction(transactionId: transaction.id, status: status)
            let updated = outcome.transaction
            guard updated.id == transaction.id,
                  updated.commodity.id == transaction.commodity.id,
                  updated.volume == transaction.volume,
                  updated.harvestSeasonId == transaction.harvestSeasonId,
                  updated.status == (status == .accept ? .accepted : .rejected) else {
                throw TransactionModel.StatusChangeError.invalidResponse
            }
            if let automatic = outcome.automaticTransaction {
                guard status == .accept, automatic.status == .automatic,
                      automatic.id != updated.id, automatic.commodity.id == updated.commodity.id,
                      automatic.volume.isFinite, automatic.volume > 0,
                      automatic.harvestSeasonId == updated.harvestSeasonId else {
                    throw TransactionModel.StatusChangeError.invalidResponse
                }
            }
            let returned = [updated] + [outcome.automaticTransaction].compactMap { $0 }
            do {
                try await transactionsLocalRepository.saveStatusOutcome(returned)
            } catch {
                // A cache failure cannot turn a confirmed server mutation into a failed acceptance.
                outcome.cacheSaveFailed = true
            }
            try await businessDataContext.commitState {
                appState.transactions.dispatch { state in
                    for item in returned { state.updateList(with: item) }
                }
            }
            return outcome
        }
    }

    func updateTransactionGeodata(
        transactionId: String,
        file: FileObject
    ) async throws {
        try await businessDataContext.withProtectedWork {
            let uploadFile: RequestModels.UpdateTransactionGeodata.UploadFile = .init(
                fileURL: file.url,
                fileName: file.id,
                mimeType: file.mimeType
            )

            try await transactionsRemoteRepository.updateTransactionGeodata(transactionId: transactionId, uploadFile: uploadFile)
        }
    }
}

// MARK: - Private Methods
private extension TransactionsInteractorImpl {
    func validateSale(volume: String, commodityId: String, season: HarvestSeason) async throws {
        try await businessDataContext.withCurrentGeneration {
            let balance: ExactSeasonalBalance?
            do {
                balance = try await creationSeasonInteractor.balance(commodityId: commodityId, seasonId: season.id)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                balance = nil
            }
            switch SeasonalSaleValidation(volume: volume, season: season, balance: balance) {
                case .sufficient, .activeShortage, .balanceUnavailable:
                    return
                case .invalidQuantity:
                    throw SeasonalSaleError.invalidQuantity
                case .invalidSelection:
                    throw CreationSeasonError.invalidSelection
                case .seasonalShortage:
                    throw SeasonalSaleError.insufficientBalance(season)
            }
        }
    }

    func convertFarmLocation(
        _ farmLocation: FarmLocation?
    ) -> (
        location: RequestModels.CreateTransaction.LocationType?,
        farmCoordinates: CLLocationCoordinate2D?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?
    ) {
        let location: RequestModels.CreateTransaction.LocationType?
        let farmCoordinates: CLLocationCoordinate2D?
        let uploadFile: RequestModels.CreateTransaction.UploadFile?
        switch farmLocation {
            case .qrCode(let file, let coordinates):
                location = .qrCode
                farmCoordinates = coordinates
                uploadFile = .init(
                    fileURL: file.url,
                    fileName: file.id,
                    mimeType: file.mimeType
                )
            case .fileManager(let file, let coordinates):
                location = .file
                farmCoordinates = coordinates
                uploadFile = .init(
                    fileURL: file.url,
                    fileName: file.id,
                    mimeType: file.mimeType
                )
            case .gps(let coordinates):
                location = .gps
                farmCoordinates = coordinates
                uploadFile = nil
            case .manual(let coordinates):
                location = .manual
                farmCoordinates = coordinates
                uploadFile = nil
            case .none:
                location = nil
                farmCoordinates = nil
                uploadFile = nil
        }

        return (location, farmCoordinates, uploadFile)
    }
}
