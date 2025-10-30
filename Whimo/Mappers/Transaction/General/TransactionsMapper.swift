//
//  TransactionsMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 01.06.2025.
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
import DatabaseKit
import RestClient

// MARK: - TransactionsMapper
struct TransactionsMapper: TransactionsMapperProtocol {
    // MARK: - Dependencies
    private let commoditiesMapper: CommoditiesMapperProtocol
    private let userMapper: UserMapperProtocol

    // MARK: - Init
    init(commoditiesMapper: CommoditiesMapperProtocol, userMapper: UserMapperProtocol) {
        self.commoditiesMapper = commoditiesMapper
        self.userMapper = userMapper
    }

    // MARK: - DTO -> Domain
    private func toDomain(from dto: ResponseModels.Transaction.TransactionType) -> TransactionModel.TransactionType {
        switch dto {
            case .producer:
                return .producer
            case .downstream:
                return .downstream
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction) -> TransactionModel.Status {
        if dto.isAutomatic {
            return .automatic
        }

        if !dto.isAutomatic && dto.type == .producer {
            return .recorded
        }

        switch dto.status {
            case .accepted:
                return .accepted
            case .rejected:
                return .rejected
            case .pending:
                return .pending
            case .noResponse:
                return .noResponse
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction.Action) -> TransactionModel.Action {
        switch dto {
            case .buy:
                return .buy
            case .sell:
                return .sell
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction.Traceability?) -> TransactionModel.Traceability? {
        switch dto {
            case .fullTraceability:
                .fullTraceability
            case .conditionalTraceability:
                .conditionalTraceability
            case .partialTraceability:
                .partialTraceability
            case .incompleteTraceability:
                .incompleteTraceability
            case .none:
                nil
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction.LocationType?) -> TransactionModel.LocationType? {
        switch dto {
            case .qrCode:
                .qrCode
            case .manual:
                .manual
            case .file:
                .file
            case .gps:
                .gps
            case .none:
                nil
        }
    }

    func toDomain(from dto: ResponseModels.Transaction) -> TransactionModel {
        .init(
            id: dto.id,
            createdAt: dto.createdAt,
            expiresAt: dto.expiresAt,
            updatedAt: dto.updatedAt,
            type: toDomain(from: dto.type),
            status: toDomain(from: dto),
            action: toDomain(from: dto.action),
            traceability: toDomain(from: dto.traceability),
            location: toDomain(from: dto.location),
            farmLatitude: dto.farmLatitude,
            farmLongitude: dto.farmLongitude,
            transactionLatitude: dto.transactionLatitude,
            transactionLongitude: dto.transactionLongitude,
            volume: dto.volume,
            isBuyingFromFarmer: dto.isBuyingFromFarmer,
            commodity: commoditiesMapper.toDomain(from: dto.commodity),
            seller: userMapper.toDomainOptional(dto: dto.seller),
            buyer: userMapper.toDomainOptional(dto: dto.buyer),
            createdById: dto.createdById,
            persistingData: .sync()
        )
    }

    // MARK: - Database -> Domain
    private func toDomain(from dbModel: DatabaseKit.Transaction.TransactionType) -> TransactionModel.TransactionType {
        switch dbModel {
            case .producer:
                return .producer
            case .downstream:
                return .downstream
        }
    }

    private func toDomain(from dbModel: DatabaseKit.Transaction.Status) -> TransactionModel.Status {
        switch dbModel {
            case .accepted:
                return .accepted
            case .rejected:
                return .rejected
            case .pending:
                return .pending
            case .noResponse:
                return .noResponse
            case .recorded:
                return .recorded
            case .automatic:
                return .automatic
        }
    }

    private func toDomain(from dbModel: DatabaseKit.Transaction.Action) -> TransactionModel.Action {
        switch dbModel {
            case .buy:
                return .buy
            case .sell:
                return .sell
        }
    }

    private func toDomain(from dto: DatabaseKit.Transaction.Traceability?) -> TransactionModel.Traceability? {
        switch dto {
            case .fullTraceability:
                    .fullTraceability
            case .conditionalTraceability:
                    .conditionalTraceability
            case .partialTraceability:
                    .partialTraceability
            case .incompleteTraceability:
                    .incompleteTraceability
            case .none:
                nil
        }
    }

    private func toDomain(from dbModel: DatabaseKit.Transaction.LocationType?) -> TransactionModel.LocationType? {
        switch dbModel {
            case .qrCode:
                .qrCode
            case .manual:
                .manual
            case .file:
                .file
            case .gps:
                .gps
            case .none:
                nil
        }
    }

    func toDomain(from dbModel: DatabaseKit.Transaction.PersistingData.File?) -> TransactionModel.PersistingData.File? {
        if let dbModel {
            return .init(
                fileURL: dbModel.fileURL,
                fileName: dbModel.fileName,
                mimeType: dbModel.mimeType
            )
        }

        return nil
    }

    func toDomain(from dbModel: DatabaseKit.Transaction.PersistingData) -> TransactionModel.PersistingData {
        let farmLocationFile = dbModel.farmLocationFile
        switch dbModel.state {
            case .onDisk:
                return .onDisk(farmLocationFile: toDomain(from: farmLocationFile))
            case .sync:
                return .sync(farmLocationFile: toDomain(from: farmLocationFile))
        }
    }

    func toDomain(from dbModel: DatabaseKit.Transaction.Node) -> TransactionModel {
        .init(
            id: dbModel.transaction.id,
            createdAt: dbModel.transaction.createdAt,
            expiresAt: dbModel.transaction.expiresAt,
            updatedAt: dbModel.transaction.updatedAt,
            type: toDomain(from: dbModel.transaction.type),
            status: toDomain(from: dbModel.transaction.status),
            action: toDomain(from: dbModel.transaction.action),
            traceability: toDomain(from: dbModel.transaction.traceability),
            location: toDomain(from: dbModel.transaction.location),
            farmLatitude: dbModel.transaction.farmLatitude,
            farmLongitude: dbModel.transaction.farmLongitude,
            transactionLatitude: dbModel.transaction.transactionLatitude,
            transactionLongitude: dbModel.transaction.transactionLongitude,
            volume: dbModel.transaction.volume,
            isBuyingFromFarmer: dbModel.transaction.isBuyingFromFarmer,
            commodity: commoditiesMapper.toDomain(from: dbModel.commodity),
            seller: userMapper.toDomain(from: dbModel.seller),
            buyer: userMapper.toDomain(from: dbModel.buyer),
            createdById: dbModel.transaction.createdById,
            persistingData: toDomain(from: dbModel.transaction.persistingData)
        )
    }

    // MARK: - Domain -> Database
    private func toDatabase(from dModel: TransactionModel.TransactionType) -> DatabaseKit.Transaction.TransactionType {
        switch dModel {
            case .producer:
                return .producer()
            case .downstream:
                return .downstream
        }
    }

    private func toDatabase(from dModel: TransactionModel.Status) -> DatabaseKit.Transaction.Status {
        switch dModel {
            case .accepted:
                return .accepted
            case .rejected:
                return .rejected
            case .pending:
                return .pending
            case .noResponse:
                return .noResponse
            case .recorded:
                return .recorded
            case .automatic:
                return .automatic
        }
    }

    private func toDatabase(from dModel: TransactionModel.Action) -> DatabaseKit.Transaction.Action {
        switch dModel {
            case .buy:
                return .buy
            case .sell:
                return .sell
        }
    }

    private func toDatabase(from dModel: TransactionModel.Traceability?) -> DatabaseKit.Transaction.Traceability? {
        switch dModel {
            case .fullTraceability:
                    .fullTraceability
            case .conditionalTraceability:
                    .conditionalTraceability
            case .partialTraceability:
                    .partialTraceability
            case .incompleteTraceability:
                    .incompleteTraceability
            case .none:
                nil
        }
    }

    private func toDatabase(from dModel: TransactionModel.LocationType?) -> DatabaseKit.Transaction.LocationType? {
        switch dModel {
            case .qrCode:
                    .qrCode
            case .manual:
                    .manual
            case .file:
                    .file
            case .gps:
                    .gps
            case .none:
                nil
        }
    }

    func toDatabase(from dModel: TransactionModel) -> DatabaseKit.Transaction {
        .init(
            id: dModel.id,
            createdAt: dModel.createdAt,
            expiresAt: dModel.expiresAt,
            updatedAt: dModel.updatedAt,
            type: toDatabase(from: dModel.type),
            status: toDatabase(from: dModel.status),
            action: toDatabase(from: dModel.action),
            traceability: toDatabase(from: dModel.traceability),
            location: toDatabase(from: dModel.location),
            farmLatitude: dModel.farmLatitude,
            farmLongitude: dModel.farmLongitude,
            transactionLatitude: dModel.transactionLatitude,
            transactionLongitude: dModel.transactionLongitude,
            volume: dModel.volume,
            isBuyingFromFarmer: dModel.isBuyingFromFarmer,
            commodityId: dModel.commodity.id,
            sellerId: dModel.seller?.id,
            buyerId: dModel.buyer?.id,
            createdById: dModel.createdById,
            persistingData: .sync()
        )
    }

    func toDatabaseNode(from dModel: TransactionModel) -> DatabaseKit.Transaction.Node {
        .init(
            transaction: toDatabase(from: dModel),
            commodity: .init(
                commodity: commoditiesMapper.toDatabase(from: dModel.commodity),
                group: commoditiesMapper.toDatabase(from: dModel.commodity.group)
            ),
            seller: userMapper.toDatabase(from: dModel.seller),
            buyer: userMapper.toDatabase(from: dModel.buyer)
        )
    }
}
