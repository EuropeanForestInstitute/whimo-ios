//
//  Response+Transaction.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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
import RestClient

private typealias Transaction = ResponseModels.Transaction

extension ResponseModels {
    // MARK: - TransactionsInfo
    public struct TransactionsInfo: AnyPaginationDataResponse {
        public let data: [Transaction]
        public let pagination: Pagination

        public init(data: [Transaction], pagination: Pagination) {
            self.data = data
            self.pagination = pagination
        }
    }

    // MARK: - SupplierTransactionsInfo
    public struct SupplierTransactionsInfo: AnyPaginationDataResponse {
        public let data: [SupplierTransaction]
        public let pagination: Pagination

        public init(data: [SupplierTransaction], pagination: Pagination) {
            self.data = data
            self.pagination = pagination
        }
    }

    // MARK: - TransactionInfo
    public struct TransactionInfo: AnyDataResponse {
        public let data: Transaction

        public init(data: Transaction) {
            self.data = data
        }
    }

    // MARK: - Transaction
    public struct Transaction: Decodable {
        public let id: String
        public let createdAt: String
        public let expiresAt: String?
        public let updatedAt: String?
        public let type: TransactionType
        public let status: Status
        public let action: Action
        public let traceability: Traceability?
        public let location: LocationType?
        public let farmLatitude: Double?
        public let farmLongitude: Double?
        public let transactionLatitude: Double?
        public let transactionLongitude: Double?
        public let commodity: CommodityGroup.Commodity
        public let volume: Double
        public let isBuyingFromFarmer: Bool
        public let isAutomatic: Bool
        public let seller: Profile?
        public let buyer: Profile?
        public let createdById: String?

        public enum CodingKeys: CodingKey {
            case id
            case createdAt
            case expiresAt
            case updatedAt
            case type
            case status
            case action
            case traceability
            case location
            case farmLatitude
            case farmLongitude
            case transactionLatitude
            case transactionLongitude
            case commodity
            case volume
            case isBuyingFromFarmer
            case isAutomatic
            case seller
            case buyer
            case createdById
        }

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
            commodity: CommodityGroup.Commodity,
            volume: Double,
            isBuyingFromFarmer: Bool,
            isAutomatic: Bool,
            seller: Profile?,
            buyer: Profile?,
            createdById: String?
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
            self.commodity = commodity
            self.volume = volume
            self.isBuyingFromFarmer = isBuyingFromFarmer
            self.isAutomatic = isAutomatic
            self.seller = seller
            self.buyer = buyer
            self.createdById = createdById
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.createdAt = try container.decode(String.self, forKey: .createdAt)
            self.expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
            self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            self.type = try container.decode(TransactionType.self, forKey: .type)
            self.status = try container.decode(Status.self, forKey: .status)
            self.action = try container.decode(Action.self, forKey: .action)
            self.traceability = try container.decodeIfPresent(Traceability.self, forKey: .traceability)
            self.location = try container.decodeIfPresent(LocationType.self, forKey: .location)
            self.farmLatitude = try container.decodeIfPresent(Double.self, forKey: .farmLatitude)
            self.farmLongitude = try container.decodeIfPresent(Double.self, forKey: .farmLongitude)
            self.transactionLatitude = try container.decodeIfPresent(Double.self, forKey: .transactionLatitude)
            self.transactionLongitude = try container.decodeIfPresent(Double.self, forKey: .transactionLongitude)
            self.commodity = try container.decode(CommodityGroup.Commodity.self, forKey: .commodity)

            if let volume = try? container.decodeIfPresent(Double.self, forKey: .volume) {
                self.volume = volume
            } else if let volume = try? container.decodeIfPresent(String.self, forKey: .volume) {
                self.volume = .init(volume) ?? .zero
            } else {
                throw DecodingError.typeMismatch(
                    Double.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Cannot decode `volume` property."
                    )
                )
            }

            self.isBuyingFromFarmer = try container.decode(Bool.self, forKey: .isBuyingFromFarmer)
            self.isAutomatic = try container.decode(Bool.self, forKey: .isAutomatic)
            self.seller = try container.decodeIfPresent(Profile.self, forKey: .seller)
            self.buyer = try container.decodeIfPresent(Profile.self, forKey: .buyer)
            self.createdById = try container.decodeIfPresent(String.self, forKey: .createdById)
        }
    }
}

// MARK: - TransactionType
extension ResponseModels.Transaction {
    public enum TransactionType: String, Decodable {
        case producer
        case downstream
        case conversion
    }
}

// MARK: - Status
extension ResponseModels.Transaction {
    public enum Status: String, Decodable {
        case accepted = "accepted"
        case rejected = "rejected"
        case pending = "pending"
        case noResponse = "no_response"
    }
}

// MARK: - Action
extension ResponseModels.Transaction {
    public enum Action: String, Decodable {
        case buy = "buying"
        case sell = "selling"
    }
}

// MARK: - Traceability
extension ResponseModels.Transaction {
    public enum Traceability: String, Decodable {
        case fullTraceability = "full"
        case conditionalTraceability = "conditional"
        case partialTraceability = "partial"
        case incompleteTraceability = "incomplete"
    }
}

// MARK: - LocationType
extension ResponseModels.Transaction {
    public enum LocationType: String, Decodable {
        case qrCode = "qr"
        case manual = "manual"
        case file = "file"
        case gps = "gps"
    }
}
