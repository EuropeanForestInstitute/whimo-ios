//
//  Request+TransactionsList.swift
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

// MARK: - TransactionsList
extension RequestModels {
    public struct TransactionsList: Encodable, Equatable {
        // MARK: - Encodable Properties
        public let searchData: SearchData
        public let pageData: PaginationRequest

        // MARK: - Local Usage Properties
        /// Cached value. Indicates is next page reachable on BE.
        /// Only for internal usage. Do not use this property to make requests.
        public var nextPage: Int?
        public var hasNextPage: Bool { nextPage != nil }

        // MARK: - Static Methods
        public static func initial(
            searchData: SearchData = .empty
        ) -> Self {
            .init(
                searchData: searchData,
                pageData: .initial
            )
        }

        public static func supplierInitial(buyerData: BuyerData) -> Self {
            .init(
                searchData: .byBuyer(buyerData),
                pageData: .initial
            )
        }

        // MARK: - Public Init
        public init(
            searchData: SearchData = .empty,
            pageData: PaginationRequest = .initial
        ) {
            self.searchData = searchData
            self.pageData = pageData
        }

        // MARK: - CodingKeys
        public enum CodingKeys: CodingKey {
            case search
            case createdAtFrom
            case createdAtTo
            case action
            case commodityGroupId
            case buyerId
            case status
            case page
            case pageSize
        }

        // MARK: - Encodable
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeIfPresent(searchData.search, forKey: CodingKeys.search)
            try container.encodeIfPresent(searchData.createdAtFrom, forKey: CodingKeys.createdAtFrom)
            try container.encodeIfPresent(searchData.createdAtTo, forKey: CodingKeys.createdAtTo)
            try container.encodeIfPresent(searchData.action, forKey: CodingKeys.action)
            try container.encodeIfPresent(searchData.buyerData?.commodityGroupId, forKey: CodingKeys.commodityGroupId)
            try container.encodeIfPresent(searchData.buyerData?.buyerId, forKey: CodingKeys.buyerId)
            try container.encodeIfPresent(searchData.buyerData?.status, forKey: CodingKeys.status)
            try container.encode(pageData.page, forKey: CodingKeys.page)
            try container.encode(pageData.pageSize, forKey: CodingKeys.pageSize)
        }
    }
}

// MARK: - SearchData
extension RequestModels.TransactionsList {
    public struct SearchData: Encodable, Equatable {
        // MARK: - Public Properties
        public let search: String?
        public let createdAtFrom: String?
        public let createdAtTo: String?
        public let action: Action?
        public let buyerData: BuyerData?

        // MARK: - Static Methods
        public static let empty: Self = .init(
            search: nil,
            createdAtFrom: nil,
            createdAtTo: nil,
            action: nil,
            buyerData: nil
        )

        public static func byBuyer(_ buyerData: BuyerData?) -> Self {
            .init(
                search: nil,
                createdAtFrom: nil,
                createdAtTo: nil,
                action: nil,
                buyerData: buyerData
            )
        }

        // MARK: - Public Init
        public init(
            search: String?,
            createdAtFrom: String?,
            createdAtTo: String?,
            action: Action?,
            buyerData: BuyerData?
        ) {
            self.search = search
            self.createdAtFrom = createdAtFrom
            self.createdAtTo = createdAtTo
            self.action = action
            self.buyerData = buyerData
        }
    }
}

// MARK: - Action
extension RequestModels.TransactionsList {
    public enum Action: String, Encodable {
        case buy = "buying"
        case sell = "selling"
    }
}

// MARK: - BuyerData
extension RequestModels.TransactionsList {
    public struct BuyerData: Encodable, Equatable {
        public let commodityGroupId: String
        public let buyerId: String
        public let status: String

        public init(commodityGroupId: String, buyerId: String, status: String = "accepted") {
            self.commodityGroupId = commodityGroupId
            self.buyerId = buyerId
            self.status = status
        }
    }
}
