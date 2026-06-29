//
//  TransactionsLocalRepositoryImpl.swift
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
import DatabaseKit
import StorageKit
import Utility

// MARK: - TransactionsLocalRepositoryImpl
final class TransactionsLocalRepositoryImpl: TransactionsLocalRepository {
    enum Error: LocalizedError {
        case objectNotFound(objectId: String)
        case cannotSaveObject

        var errorDescription: String? {
            switch self {
                case .objectNotFound:
                    "Object not found."
                case .cannotSaveObject:
                    "Cannot save object."
            }
        }
    }

    // MARK: - Dependencies
    private let database: DatabaseKit.Database
    private let commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol
    private let transactionsMapper: TransactionsMapperProtocol
    private let transactionsOfflineMapper: TransactionsOfflineMapperProtocol
    private let userMapper: UserMapperProtocol
    private let userOfflineMapper: UserOfflineMapperProtocol
    private let keychainStore: AnyStorage<KeychainStore>

    // MARK: - Init
    init(
        database: DatabaseKit.Database,
        commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol,
        transactionsMapper: TransactionsMapperProtocol,
        transactionsOfflineMapper: TransactionsOfflineMapperProtocol,
        userMapper: UserMapperProtocol,
        userOfflineMapper: UserOfflineMapperProtocol,
        keychainStore: AnyStorage<KeychainStore>
    ) {
        self.database = database
        self.commoditiesGroupsMapper = commoditiesGroupsMapper
        self.transactionsMapper = transactionsMapper
        self.transactionsOfflineMapper = transactionsOfflineMapper
        self.userMapper = userMapper
        self.userOfflineMapper = userOfflineMapper
        self.keychainStore = keychainStore
    }

    // MARK: - TransactionsLocalRepository
    // MARK: - Fetch
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        let userModel: UserModel? = keychainStore.get(.user)
        let fetchRequest = DatabaseKit.Transaction.Node
            .filter(
                searchText: pagination.searchData.search ?? "",
                action: pagination.searchData.action?.rawValue,
                dateFrom: pagination.searchData.createdAtFrom,
                dateTo: pagination.searchData.createdAtTo,
                refersTo: userModel?.id
            )

        // fetch transactions
        let limit = pagination.pageData.pageSize
        let currentPage = max(.zero, pagination.pageData.page - 1)
        let offset = limit * currentPage

        let totalCount: Int = try await database.readCount(fetchRequest)
        let dbModels = try await database.readAll(
            fetchRequest
                .limit(limit, offset: offset)
        )
        let domainModels: [TransactionModel] = dbModels.map(transactionsMapper.toDomain)

        let page = pagination.pageData.page
        let totalPages: Int = (totalCount + limit - 1) / limit
        let previousPage: Int? = page > 1 ? page - 1 : nil
        let nextPage: Int? = page < totalPages ? page + 1 : nil

        let pagination: RestClient.Pagination = .init(
            pageSize: pagination.pageData.pageSize,
            nextPage: nextPage,
            previousPage: previousPage,
            count: totalCount,
            totalPages: totalPages,
            page: pagination.pageData.page
        )

        return (list: .init(uniqueElements: domainModels), pagination: pagination)
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        guard
            let dbModels = try await database.readOne(
                DatabaseKit.Transaction.Node
                    .all()
                    .filter(key: id)
            )
        else { throw Error.objectNotFound(objectId: id) }

        let domainModel = transactionsMapper.toDomain(from: dbModels)
        return domainModel
    }

    func fetchOnDiskTransactions() async throws -> IdentifiedArrayOf<TransactionModel> {
        let dbModels = try await database.readAll(
            DatabaseKit.Transaction.Node
                .allOnDisk()
        )
        let domainModels: [TransactionModel] = dbModels.map(transactionsMapper.toDomain)
        return .init(uniqueElements: domainModels)
    }

    // MARK: - Save
    func save(_ model: TransactionModel) async throws {
        let commodityGroup = commoditiesGroupsMapper.toDatabase(from: model.commodity.group)
        let commodity = commoditiesGroupsMapper.toDatabase(from: model.commodity, parrentId: model.commodity.group.id)
        let transaction = transactionsMapper.toDatabase(from: model)

        try await database.save { [userMapper = userMapper] db in
            try commodityGroup.save(db)
            try commodity.save(db)
            if let seller = userMapper.toDatabase(from: model.seller) {
                try seller.save(db)
            }
            if let buyer = userMapper.toDatabase(from: model.buyer) {
                try buyer.save(db)
            }
            try transaction.save(db)
        }
    }

    func saveProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool
    ) async throws -> TransactionModel {
        let userModel: UserModel? = keychainStore.get(.user)

        guard let userId = userModel?.id else {
            throw Error.cannotSaveObject
        }

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
        let offlineTransaction = transactionsOfflineMapper.toDatabase(from: request, buyerId: userId)

        try await database.save(offlineTransaction)
        let transaction = try await fetchTransaction(by: offlineTransaction.id)

        return transaction
    }

    func saveDownstreamTransaction(
        commodityId: String,
        volume: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        action: TransactionModel.Action,
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
    ) async throws -> TransactionModel {
        let userModel: UserModel? = keychainStore.get(.user)

        guard let userId = userModel?.id else {
            throw Error.cannotSaveObject
        }

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
        let recipient = userOfflineMapper.toDatabase(from: request.transactionData.recipient)
        let offlineTransaction = transactionsOfflineMapper.toDatabase(
            from: request,
            creatorId: userId,
            recipientId: recipient.id
        )

        try await database.save(recipient)
        try await database.save(offlineTransaction)
        let transaction = try await fetchTransaction(by: offlineTransaction.id)

        return transaction
    }

    // MARK: - Delete
    func delete(_ transaction: TransactionModel) async throws {
        let dbModel = transactionsMapper.toDatabase(from: transaction)
        try await database.delete(dbModel)
    }
    func deleteTxRecepient(_ user: UserModel?) async throws {
        let dbModel = userMapper.toDatabase(from: user)
        if let dbModel {
            try await database.delete(dbModel)
        }
    }
}
