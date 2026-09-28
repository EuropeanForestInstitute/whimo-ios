//
//  TransactionsRemoteRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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
import Targets

final class TransactionsRemoteRepositoryImpl: TransactionsRemoteRepository {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let transactionsTarget: TransactionsTarget
    private let transactionsMapper: TransactionsMapperProtocol
    private let supplierTransactionMapper: SupplierTransactionMapperProtocol

    // MARK: - Init
    init(
        transactionsTarget: TransactionsTarget,
        transactionsMapper: TransactionsMapperProtocol,
        supplierTransactionMapper: SupplierTransactionMapperProtocol,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.transactionsTarget = transactionsTarget
        self.transactionsMapper = transactionsMapper
        self.supplierTransactionMapper = supplierTransactionMapper
    }

    // MARK: - TransactionsRemoteRepository
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        try await businessDataContext.withCurrentGeneration {
            let response = try await transactionsTarget.transactionsList(pagination)
            let transactionsList = response
                .data
                .map(transactionsMapper.toDomain)

            return (.init(uniqueElements: transactionsList), response.pagination)
        }
    }

    func fetchSupplierTransactions(with pagination: TransactionsPagination) async throws -> SupplierTransactionsData {
        try await businessDataContext.withCurrentGeneration {
            let response = try await transactionsTarget.getSuppliersTransaction(pagination)
            let transactionsList = response
                .data
                .map(supplierTransactionMapper.toDomain)

            return (.init(uniqueElements: transactionsList), response.pagination)
        }
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.GetTransaction = .init(transactionId: id)
            let response = try await transactionsTarget.getTransaction(request)
            let transaction = transactionsMapper.toDomain(from: response.data)

            return transaction
        }
    }

    @discardableResult
    func createProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool,
        season: HarvestSeason
    ) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            var latitude: String?
            var longitude: String?

            var txLatitude: String?
            var txLongitude: String?

            if let latitudeDegrees = farmCoordinates?.latitude {
                latitude = "\(latitudeDegrees)"
            }
            if let longitudeDegrees = farmCoordinates?.longitude {
                longitude = "\(longitudeDegrees)"
            }
            if let latitudeDegrees = transactionCoordinates?.latitude {
                txLatitude = "\(latitudeDegrees)"
            }
            if let longitudeDegrees = transactionCoordinates?.longitude {
                txLongitude = "\(longitudeDegrees)"
            }
            let transactionData: RequestModels.CreateTransaction.Producer.TransactionData = .init(
                commodityId: commodityId,
                volume: volume,
                location: location,
                farmLatitude: latitude,
                farmLongitude: longitude,
                transactionLatitude: txLatitude,
                transactionLongitude: txLongitude,
                recipient: inviteRecipient,
                isBuyingFromFarmer: isBuyingFromFarmer,
                harvestSeasonId: season.id
            )
            let request: RequestModels.CreateTransaction.Producer = .init(
                transactionData: transactionData,
                uploadFile: uploadFile
            )
            let response = try await transactionsTarget.createProducerTransaction(request)
            let transaction = transactionsMapper.toDomain(from: response.data)

            return transaction
        }
    }

    @discardableResult
    func createDownstreamTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        transactionCoordinates: CLLocationCoordinate2D?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        volume: String,
        action: TransactionModel.Action,
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient,
        season: HarvestSeason?
    ) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            let requestAction: RequestModels.CreateTransaction.Downstream.Action
            var latitude: String?
            var longitude: String?

            var txLatitude: String?
            var txLongitude: String?

            if let latitudeDegrees = farmCoordinates?.latitude {
                latitude = "\(latitudeDegrees)"
            }
            if let longitudeDegrees = farmCoordinates?.longitude {
                longitude = "\(longitudeDegrees)"
            }
            if let latitudeDegrees = transactionCoordinates?.latitude {
                txLatitude = "\(latitudeDegrees)"
            }
            if let longitudeDegrees = transactionCoordinates?.longitude {
                txLongitude = "\(longitudeDegrees)"
            }
            switch action {
                case .buy:
                    requestAction = .buy
                case .sell:
                    requestAction = .sell
            }
            let transactionData: RequestModels.CreateTransaction.Downstream.TransactionData = .init(
                commodityId: commodityId,
                volume: volume,
                location: location,
                farmLatitude: latitude,
                farmLongitude: longitude,
                transactionLatitude: txLatitude,
                transactionLongitude: txLongitude,
                action: requestAction,
                recipient: recipient,
                harvestSeasonId: season?.id
            )
            let request: RequestModels.CreateTransaction.Downstream = .init(
                transactionData: transactionData,
                uploadFile: uploadFile
            )
            let response = try await transactionsTarget.createDownstreamTransaction(request)
            let transaction = transactionsMapper.toDomain(from: response.data)

            return transaction
        }
    }

    func updateTransaction(transactionId: String, status: TransactionModel.StatusChange) async throws -> TransactionModel.StatusOutcome {
        try await businessDataContext.withCurrentGeneration {
            let request = RequestModels.UpdateTransactionStatus(transactionId: transactionId, status: status == .accept ? .accept : .reject)
            do {
                let response = try await transactionsTarget.updateTransaction(request)
                return .init(transaction: transactionsMapper.toDomain(from: response.data.transaction),
                             automaticTransaction: response.data.automaticTransaction.map(transactionsMapper.toDomain))
            } catch RestClient.RestError.clientError(_, let code, _) where code.rawValue == 409 {
                throw TransactionModel.StatusChangeError.conflict
            } catch {
                // Do not expose another participant's balance or claim a mutation after an incomplete response.
                throw TransactionModel.StatusChangeError.unconfirmed
            }
        }
    }

    func updateTransactionGeodata(
        transactionId: String,
        uploadFile: RequestModels.UpdateTransactionGeodata.UploadFile
    ) async throws {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.UpdateTransactionGeodata = .init(
                transactionId: transactionId,
                transactionData: .init(location: .file),
                uploadFile: uploadFile
            )
            try await transactionsTarget.updateTransactionGeodata(request)
        }
    }

    @discardableResult
    func requestTransactionGeodata(transactionId: String) async throws -> ResponseModels.RequestTransactionGeodata {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.RequestTransactionGeodata = .init(transactionId: transactionId)
            return try await transactionsTarget.requestTransactionGeodata(request)
        }
    }

    func resendTransactionNotification(transactionId: String) async throws -> ResponseModels.ResendTransactionNotification {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.ResendTransactionNotification = .init(transactionId: transactionId)
            return try await transactionsTarget.resendTransactionNotification(request)
        }
    }
}
