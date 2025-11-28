//
//  Response+SupplierTransaction.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.06.2025.
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

// MARK: - SupplierTransaction
extension ResponseModels {
    public struct SupplierTransaction: Decodable {
        public let id: String
        public let createdAt: String
        public let type: Transaction.TransactionType
        public let status: Transaction.Status
        public let traceability: Transaction.Traceability?
        public let location: Transaction.LocationType?
        public let latitude: Double?
        public let longitude: Double?
        public let commodity: CommodityGroup.Commodity
        public let volume: Double
        public let isBuyingFromFarmer: Bool
        public let isAutomatic: Bool
        public let seller: Profile?
        public let buyer: Profile?
        public let createdById: String?

        public init(
            id: String,
            createdAt: String,
            type: Transaction.TransactionType,
            status: Transaction.Status,
            traceability: Transaction.Traceability?,
            location: Transaction.LocationType?,
            latitude: Double?,
            longitude: Double?,
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
            self.type = type
            self.status = status
            self.traceability = traceability
            self.location = location
            self.latitude = latitude
            self.longitude = longitude
            self.commodity = commodity
            self.volume = volume
            self.isBuyingFromFarmer = isBuyingFromFarmer
            self.isAutomatic = isAutomatic
            self.seller = seller
            self.buyer = buyer
            self.createdById = createdById
        }
    }
}
