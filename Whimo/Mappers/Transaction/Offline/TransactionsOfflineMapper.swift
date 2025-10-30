//
//  TransactionsOfflineMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 26.06.2025.
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
struct TransactionsOfflineMapper: TransactionsOfflineMapperProtocol {
    // MARK: - Dependencies
    private let dateFormatter: DateTimeFormatter = .iso8601

    // MARK: - Init

    // MARK: - DTO -> Database
    private func toDatabase(from dto: RequestModels.CreateTransaction.LocationType?) -> DatabaseKit.Transaction.LocationType? {
        switch dto {
            case .qrCode:
                return .qrCode
            case .manual:
                return .manual
            case .file:
                return .file
            case .gps:
                return .gps
            case .none:
                return nil
        }
    }

    private func toDatabase(from dto: RequestModels.CreateTransaction.UploadFile?) -> DatabaseKit.Transaction.PersistingData.File? {
        if let dto {
            return .init(
                fileURL: dto.fileURL,
                fileName: dto.fileName,
                mimeType: dto.mimeType
            )
        }

        return nil
    }

    private func toDTO(from dModel: TransactionModel.PersistingData.File?) -> RequestModels.CreateTransaction.UploadFile? {
        if let dModel {
            return .init(
                fileURL: dModel.fileURL,
                fileName: dModel.fileName,
                mimeType: dModel.mimeType
            )
        }

        return nil
    }

    // MARK: - Producer DTO -> Database
    func toDatabase(from dto: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?) -> DatabaseKit.Transaction.TransactionType.Recipient? {
        guard let dto else { return nil }

        return .init(email: dto.email, phone: dto.phone)
    }

    func toDatabase(
        from dto: RequestModels.CreateTransaction.Producer,
        buyerId: String
    ) -> DatabaseKit.Transaction {
        let createdAt = dateFormatter.format(date: .now)

        return .init(
            id: UUID().uuidString,
            createdAt: createdAt,
            expiresAt: nil,
            updatedAt: createdAt,
            type: .producer(inviteRecipient: toDatabase(from: dto.transactionData.recipient)),
            status: .recorded,
            action: .buy,
            traceability: nil,
            location: toDatabase(from: dto.transactionData.location),
            farmLatitude: .init(dto.transactionData.farmLatitude ?? ""),
            farmLongitude: .init(dto.transactionData.farmLongitude ?? ""),
            transactionLatitude: .init(dto.transactionData.transactionLatitude ?? ""),
            transactionLongitude: .init(dto.transactionData.transactionLongitude ?? ""),
            volume: .init(dto.transactionData.volume) ?? .zero,
            isBuyingFromFarmer: true,
            commodityId: dto.transactionData.commodityId,
            sellerId: nil,
            buyerId: buyerId,
            createdById: buyerId,
            persistingData: .onDisk(farmLocationFile: toDatabase(from: dto.uploadFile))
        )
    }

    // MARK: - Downstream DTO -> Database
    private func toDatabase(
        from dto: RequestModels.CreateTransaction.Downstream.Action
    ) -> DatabaseKit.Transaction.Action {
        switch dto {
            case .buy:
                .buy
            case .sell:
                .sell
        }
    }

    func toDatabase(
        from dto: RequestModels.CreateTransaction.Downstream,
        creatorId: String,
        recipientId: String
    ) -> DatabaseKit.Transaction {
        let action: DatabaseKit.Transaction.Action = toDatabase(from: dto.transactionData.action)
        let sellerId: String?
        let buyerId: String?

        switch action {
            case .buy:
                sellerId = recipientId
                buyerId = creatorId
            case .sell:
                sellerId = creatorId
                buyerId = recipientId
        }
        let createdAt = dateFormatter.format(date: .now)

        return .init(
            id: UUID().uuidString,
            createdAt: createdAt,
            expiresAt: nil,
            updatedAt: createdAt,
            type: .downstream,
            status: .pending,
            action: action,
            traceability: nil,
            location: toDatabase(from: dto.transactionData.location),
            farmLatitude: .init(dto.transactionData.farmLatitude ?? ""),
            farmLongitude: .init(dto.transactionData.farmLongitude ?? ""),
            transactionLatitude: .init(dto.transactionData.transactionLatitude ?? ""),
            transactionLongitude: .init(dto.transactionData.transactionLongitude ?? ""),
            volume: .init(dto.transactionData.volume) ?? .zero,
            isBuyingFromFarmer: false,
            commodityId: dto.transactionData.commodityId,
            sellerId: sellerId,
            buyerId: buyerId,
            createdById: creatorId,
            persistingData: .onDisk(farmLocationFile: toDatabase(from: dto.uploadFile))
        )
    }

    // MARK: - Domain -> DTO
    // MARK: - Producer Domain -> DTO
    private func toDTO(from dModel: TransactionModel.LocationType?) -> RequestModels.CreateTransaction.LocationType? {
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
                .none
        }
    }

    private func toDTO(from dModel: TransactionModel) -> RequestModels.CreateTransaction.Producer.TransactionData {
        var latitude: String?
        var longitude: String?

        var txLatitude: String?
        var txLongitude: String?

        if let value = dModel.farmLatitude {
            latitude = "\(value)"
        }
        if let value = dModel.farmLongitude {
            longitude = "\(value)"
        }
        if let latitudeDegrees = dModel.transactionLatitude {
            txLatitude = "\(latitudeDegrees)"
        }
        if let longitudeDegrees = dModel.transactionLongitude {
            txLongitude = "\(longitudeDegrees)"
        }

        return .init(
            commodityId: dModel.commodity.id,
            volume: "\(dModel.volume)",
            location: toDTO(from: dModel.location),
            farmLatitude: latitude,
            farmLongitude: longitude,
            transactionLatitude: txLatitude,
            transactionLongitude: txLongitude,
            isBuyingFromFarmer: dModel.isBuyingFromFarmer
        )
    }

    func toDTO(from dModel: TransactionModel) -> RequestModels.CreateTransaction.Producer {
        .init(
            transactionData: toDTO(from: dModel),
            uploadFile: toDTO(from: dModel.persistingData.farmLocationFile)
        )
    }

    // MARK: - Downstream Domain -> DTO
    private func toDTO(from dModel: TransactionModel.Action) -> RequestModels.CreateTransaction.Downstream.Action {
        switch dModel {
            case .buy:
                .buy
            case .sell:
                .sell
        }
    }

    private func toRecipientDTO(from dModel: UserModel?) -> RequestModels.CreateTransaction.Downstream.TransactionData.Recipient {
        var username: String?
        var email: String?
        var phone: String?

        if let value = dModel?.username, value != UserModel.kOfflineModeRecipientName {
            username = value
        }

        for gadget in dModel?.gadgets ?? [] {
            if gadget.type == .email {
                email = gadget.identifier
            }
            if gadget.type == .phone {
                phone = gadget.identifier
            }
        }

        return .init(
            name: username,
            email: email,
            phone: phone
        )
    }

    private func toDTO(from dModel: TransactionModel) -> RequestModels.CreateTransaction.Downstream.TransactionData.Recipient {
        switch dModel.action {
            case .buy:
                return toRecipientDTO(from: dModel.seller)
            case .sell:
                return toRecipientDTO(from: dModel.buyer)
        }
    }

    private func toDTO(from dModel: TransactionModel) -> RequestModels.CreateTransaction.Downstream.TransactionData {
        var latitude: String?
        var longitude: String?

        var txLatitude: String?
        var txLongitude: String?

        if let value = dModel.farmLatitude {
            latitude = "\(value)"
        }
        if let value = dModel.farmLongitude {
            longitude = "\(value)"
        }
        if let latitudeDegrees = dModel.transactionLatitude {
            txLatitude = "\(latitudeDegrees)"
        }
        if let longitudeDegrees = dModel.transactionLongitude {
            txLongitude = "\(longitudeDegrees)"
        }

        return .init(
            commodityId: dModel.commodity.id,
            volume: "\(dModel.volume)",
            location: toDTO(from: dModel.location),
            farmLatitude: latitude,
            farmLongitude: longitude,
            transactionLatitude: txLatitude,
            transactionLongitude: txLongitude,
            action: toDTO(from: dModel.action),
            recipient: toDTO(from: dModel)
        )
    }

    func toDTO(from dModel: TransactionModel) -> RequestModels.CreateTransaction.Downstream {
        .init(
            transactionData: toDTO(from: dModel),
            uploadFile: toDTO(from: dModel.persistingData.farmLocationFile)
        )
    }
}
