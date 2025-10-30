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
    private let transactionsTarget: TransactionsTarget
    private let transactionsMapper: TransactionsMapperProtocol
    private let supplierTransactionMapper: SupplierTransactionMapperProtocol

    // MARK: - Init
    init(
        transactionsTarget: TransactionsTarget,
        transactionsMapper: TransactionsMapperProtocol,
        supplierTransactionMapper: SupplierTransactionMapperProtocol
    ) {
        self.transactionsTarget = transactionsTarget
        self.transactionsMapper = transactionsMapper
        self.supplierTransactionMapper = supplierTransactionMapper
    }

    // MARK: - TransactionsRemoteRepository
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        let response = try await transactionsTarget.transactionsList(pagination)
        let transactionsList = response
            .data
            .map(transactionsMapper.toDomain)

        return (.init(uniqueElements: transactionsList), response.pagination)
    }

    func fetchSupplierTransactions(with pagination: TransactionsPagination) async throws -> SupplierTransactionsData {
        let response = try await transactionsTarget.getSuppliersTransaction(pagination)
        let transactionsList = response
            .data
            .map(supplierTransactionMapper.toDomain)

        return (.init(uniqueElements: transactionsList), response.pagination)
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        let request: RequestModels.GetTransaction = .init(transactionId: id)
        let response = try await transactionsTarget.getTransaction(request)
        let transaction = transactionsMapper.toDomain(from: response.data)

        return transaction
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
        isBuyingFromFarmer: Bool
    ) async throws -> TransactionModel {
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
            isBuyingFromFarmer: isBuyingFromFarmer
        )
        let request: RequestModels.CreateTransaction.Producer = .init(
            transactionData: transactionData,
            uploadFile: uploadFile
        )
        let response = try await transactionsTarget.createProducerTransaction(request)
        let transaction = transactionsMapper.toDomain(from: response.data)

        return transaction
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
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
    ) async throws -> TransactionModel {
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
            recipient: recipient
        )
        let request: RequestModels.CreateTransaction.Downstream = .init(
            transactionData: transactionData,
            uploadFile: uploadFile
        )
        let response = try await transactionsTarget.createDownstreamTransaction(request)
        let transaction = transactionsMapper.toDomain(from: response.data)

        return transaction
    }

    func updateTransaction(transactionId: String, status: RequestModels.UpdateTransactionStatus.Status) async throws {
        let request: RequestModels.UpdateTransactionStatus = .init(transactionId: transactionId, status: status)
        try await transactionsTarget.updateTransaction(request)
    }

    func updateTransactionGeodata(
        transactionId: String,
        uploadFile: RequestModels.UpdateTransactionGeodata.UploadFile
    ) async throws {
        let request: RequestModels.UpdateTransactionGeodata = .init(
            transactionId: transactionId,
            transactionData: .init(location: .file),
            uploadFile: uploadFile
        )
        try await transactionsTarget.updateTransactionGeodata(request)
    }

    @discardableResult
    func requestTransactionGeodata(transactionId: String) async throws -> ResponseModels.RequestTransactionGeodata {
        let request: RequestModels.RequestTransactionGeodata = .init(transactionId: transactionId)
        return try await transactionsTarget.requestTransactionGeodata(request)
    }

    func resendTransactionNotification(transactionId: String) async throws -> ResponseModels.ResendTransactionNotification {
        let request: RequestModels.ResendTransactionNotification = .init(transactionId: transactionId)
        return try await transactionsTarget.resendTransactionNotification(request)
    }
}
