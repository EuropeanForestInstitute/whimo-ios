//
//  TransactionsServiceImpl.swift
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

final class TransactionsServiceImpl: TransactionsService {
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

    // MARK: - Dependencies
    private let appState: AppState
    private let transactionsRemoteRepository: TransactionsRemoteRepository
    private let transactionsCachingRepository: TransactionsCachingRepository

    // MARK: - Init
    init(
        appState: AppState,
        transactionsRemoteRepository: TransactionsRemoteRepository,
        transactionsCachingRepository: TransactionsCachingRepository
    ) {
        self.appState = appState
        self.transactionsRemoteRepository = transactionsRemoteRepository
        self.transactionsCachingRepository = transactionsCachingRepository
    }

    // MARK: - TransactionsService
    func fetchTransactions(
        searchData: TransactionsPagination.SearchData,
        refresh: Bool
    ) async throws {
        let oldPagination = appState.transactions.value.pagination
        let pagination: TransactionsPagination

        if !refresh, let oldPagination {
            pagination = .init(
                searchData: searchData,
                pageData: .init(
                    page: oldPagination.pageData.page + 1,
                    pageSize: oldPagination.pageData.pageSize
                )
            )
        } else {
            pagination = .init(searchData: searchData)
        }

        appState.transactions.dispatch { state in
            state.list.setIsLoading()
        }
        do {
            let responseData = try await transactionsCachingRepository.fetchTransactions(with: pagination)
            let updatedPageData: PaginationRequest = .init(
                page: responseData.pagination.nextPage == nil ? oldPagination?.pageData.page ?? PaginationRequest.initial.page : pagination.pageData.page,
                pageSize: pagination.pageData.pageSize
            )
            var updatedPagination: TransactionsPagination = .init(
                searchData: searchData,
                pageData: updatedPageData
            )
            updatedPagination.nextPage = responseData.pagination.nextPage

            let currentList: IdentifiedArrayOf<TransactionModel> = refresh ? .init() : appState.transactions.value.list.value ?? []
            let updatingList = appState.transactions.value.updatingList
            let loadedList = responseData.list.map { item in
                guard
                    let updatingItem = updatingList[id: item.id],
                    updatingItem.persistingData.state == .uploading
                else { return item }

                return updatingItem
            }
            let updatedList = currentList + loadedList

            appState.transactions.dispatch { state in
                state.list = .loaded(value: updatedList)
                state.pagination = updatedPagination
            }
        } catch {
            appState.transactions.dispatch { state in
                state.list = .failed(error: error)
            }
            throw error
        }
    }

    func fetchSuppliersTransactions(
        commodityGroupId: String,
        buyerId: String,
        oldPagination: TransactionsPagination?,
        refresh: Bool
    ) async throws -> (list: IdentifiedArrayOf<SupplierTransactionModel>, pagination: TransactionsPagination) {
        let pagination: TransactionsPagination

        if !refresh, let oldPagination {
            pagination = .init(
                searchData: .byBuyer(.init(
                    commodityGroupId: commodityGroupId,
                    buyerId: buyerId
                )),
                pageData: .init(
                    page: oldPagination.pageData.page + 1,
                    pageSize: oldPagination.pageData.pageSize
                )
            )
        } else {
            pagination = .supplierInitial(buyerData: .init(
                commodityGroupId: commodityGroupId,
                buyerId: buyerId
            ))
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

    @discardableResult
    func fetchTransaction(by id: String) async throws -> TransactionModel {
        let transaction = try await transactionsCachingRepository.fetchTransaction(by: id)

        appState.transactions.dispatch { state in
            var currentList: IdentifiedArrayOf<TransactionModel> = state.list.value ?? []
            currentList[id: transaction.id] = transaction
            state.list = .loaded(value: currentList)
        }

        return transaction
    }

    func createProducerTransaction(
        farmLocation: FarmLocation?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        isBuyingFromFarmer: Bool,
        transactionCoordinates: CLLocationCoordinate2D?,
        inviteRecipient: TransactionType.Recipient?
    ) async throws {
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
            isBuyingFromFarmer: isBuyingFromFarmer
        )

        let currentList: IdentifiedArrayOf<TransactionModel> = appState.transactions.value.list.value ?? []
        let updatedList: IdentifiedArrayOf<TransactionModel> = [transaction] + currentList
        appState.transactions[\.list] = .loaded(value: updatedList)
    }

    func createDownstreamTransaction(
        farmLocation: FarmLocation?,
        transactionCoordinates: CLLocationCoordinate2D?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        action: TransactionModel.Action,
        recipient: TransactionType.Recipient
    ) async throws {
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
            recipient: requestRecipient
        )

        let currentList: IdentifiedArrayOf<TransactionModel> = appState.transactions.value.list.value ?? []
        let updatedList: IdentifiedArrayOf<TransactionModel> = [transaction] + currentList
        appState.transactions[\.list] = .loaded(value: updatedList)
    }

    func updateTransaction(
        transactionId: String,
        status: RequestModels.UpdateTransactionStatus.Status
    ) async throws -> TransactionModel {
        try await transactionsRemoteRepository.updateTransaction(transactionId: transactionId, status: status)
        let transaction = try await transactionsCachingRepository.fetchTransaction(by: transactionId)

        appState.transactions.dispatch { state in
            var currentList: IdentifiedArrayOf<TransactionModel> = state.list.value ?? []
            currentList[id: transaction.id] = transaction
            state.list = .loaded(value: currentList)
        }

        return transaction
    }

    func updateTransactionGeodata(
        transactionId: String,
        file: FileObject
    ) async throws {
        let uploadFile: RequestModels.UpdateTransactionGeodata.UploadFile = .init(
            fileURL: file.url,
            fileName: file.id,
            mimeType: file.mimeType
        )

        try await transactionsRemoteRepository.updateTransactionGeodata(transactionId: transactionId, uploadFile: uploadFile)
    }
}

// MARK: - Private Methods
private extension TransactionsServiceImpl {
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
