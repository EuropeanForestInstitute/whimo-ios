//
//  Transaction.swift
//  Database
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
import GRDB
import Utility

// MARK: - Transaction
public struct Transaction: Identifiable, AutoStringConvertible, Equatable {
    public var id: String
    public var createdAt: String
    public var expiresAt: String?
    public let updatedAt: String?
    public var type: TransactionType
    public var status: Status
    public var action: Action
    public var traceability: Traceability?
    public var location: LocationType?
    public var farmLatitude: Double?
    public var farmLongitude: Double?
    public let transactionLatitude: Double?
    public let transactionLongitude: Double?
    public var volume: Double
    public var isBuyingFromFarmer: Bool
    public var commodityId: String?
    public var sellerId: String?
    public var buyerId: String?
    public var createdById: String?
    public var persistingData: PersistingData

    public init(
        id: String,
        createdAt: String,
        expiresAt: String?,
        updatedAt: String?,
        type: TransactionType,
        status: Status,
        action: Action,
        traceability: Traceability?,
        location: LocationType?,
        farmLatitude: Double?,
        farmLongitude: Double?,
        transactionLatitude: Double?,
        transactionLongitude: Double?,
        volume: Double,
        isBuyingFromFarmer: Bool,
        commodityId: String,
        sellerId: String?,
        buyerId: String?,
        createdById: String?,
        persistingData: PersistingData
    ) {
        self.id = id
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.updatedAt = updatedAt
        self.type = type
        self.status = status
        self.action = action
        self.traceability = traceability
        self.location = location
        self.farmLatitude = farmLatitude
        self.farmLongitude = farmLongitude
        self.transactionLatitude = transactionLatitude
        self.transactionLongitude = transactionLongitude
        self.volume = volume
        self.isBuyingFromFarmer = isBuyingFromFarmer
        self.commodityId = commodityId
        self.sellerId = sellerId
        self.buyerId = buyerId
        self.createdById = createdById
        self.persistingData = persistingData
    }
}

// MARK: - Transaction+Record
extension Transaction: StorePersistable {
    public static var databaseTableName: String { "transaction" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let createdAt = Column(CodingKeys.createdAt)
        public static let expiresAt = Column(CodingKeys.expiresAt)
        public static let updatedAt = Column(CodingKeys.updatedAt)
        public static let type = Column(CodingKeys.type)
        public static let status = Column(CodingKeys.status)
        public static let action = Column(CodingKeys.action)
        public static let location = Column(CodingKeys.location)
        public static let farmLatitude = Column(CodingKeys.farmLatitude)
        public static let farmLongitude = Column(CodingKeys.farmLongitude)
        public static let transactionLatitude = Column(CodingKeys.transactionLatitude)
        public static let transactionLongitude = Column(CodingKeys.transactionLongitude)
        public static let volume = Column(CodingKeys.volume)
        public static let commodityId = Column(CodingKeys.commodityId)
        public static let sellerId = Column(CodingKeys.sellerId)
        public static let buyerId = Column(CodingKeys.buyerId)
        public static let createdById = Column(CodingKeys.createdById)
        public static let persistingData = Column(CodingKeys.persistingData)
    }
}

// MARK: - Transaction+Associations
extension Transaction {
    public static let commodity = belongsTo(
        Commodity.self,
        using: ForeignKey([Columns.commodityId])
    )
    public var commodity: QueryInterfaceRequest<Commodity> {
        request(for: Transaction.commodity)
    }

    static let sellerForeignKey = ForeignKey([Columns.sellerId])
    public static let seller = belongsTo(
        User.self,
        using: sellerForeignKey
    )
    public var seller: QueryInterfaceRequest<User> {
        request(for: Transaction.seller)
    }

    static let buyerForeignKey = ForeignKey([Columns.buyerId])
    public static let buyer = belongsTo(
        User.self,
        using: buyerForeignKey
    )
    public var buyer: QueryInterfaceRequest<User> {
        request(for: Transaction.buyer)
    }
}

// MARK: - TransactionType
extension Transaction {
    public enum TransactionType: StoreConvertible, Equatable {
        case producer(inviteRecipient: Recipient? = nil)
        case downstream

        // MARK: - Recipient
        public struct Recipient: StoreConvertible, Equatable {
            public let name: String?
            public let email: String?
            public let phone: String?

            public init(
                name: String? = nil,
                email: String? = nil,
                phone: String? = nil
            ) {
                self.name = name
                self.email = email
                self.phone = phone
            }

            public static func name(_ value: String) -> Self {
                fatalError("Cannot initialize invite recipient object with `name` property. User not sign up yet.")
            }

            public static func email(_ value: String) -> Self {
                .init(email: value)
            }

            public static func phone(_ value: String) -> Self {
                .init(phone: value)
            }
        }
    }
}

// MARK: - Status
extension Transaction {
    public enum Status: String, StoreConvertible, Equatable {
        case accepted
        case rejected
        case pending
        case noResponse
        case recorded
        case automatic
    }
}

// MARK: - Action
extension Transaction {
    public enum Action: String, StoreConvertible, Equatable {
        case buy = "buying"
        case sell = "selling"
    }
}

// MARK: - Traceability
extension Transaction {
    public enum Traceability: String, StoreConvertible, Equatable {
        case fullTraceability
        case conditionalTraceability
        case partialTraceability
        case incompleteTraceability
    }
}

// MARK: - LocationType
extension Transaction {
    public enum LocationType: String, StoreConvertible, Equatable {
        case qrCode = "qr"
        case manual = "manual"
        case file = "file"
        case gps = "gps"
    }
}

// MARK: - PersistingData
extension Transaction {
    public struct PersistingData: StoreConvertible, Equatable {
        public let farmLocationFile: File?
        public let state: State

        private init(farmLocationFile: File?, state: State) {
            self.farmLocationFile = farmLocationFile
            self.state = state
        }

        public static func onDisk(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .onDisk)
        }

        public static func sync(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .sync)
        }

        // MARK: - State
        public enum State: StoreConvertible, Equatable {
            case onDisk
            case sync
        }
    }
}

// MARK: - File
extension Transaction.PersistingData {
    public struct File: StoreConvertible, Equatable {
        public let fileURL: URL
        public let fileName: String
        public let mimeType: String

        public init(fileURL: URL, fileName: String, mimeType: String) {
            self.fileURL = fileURL
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}
