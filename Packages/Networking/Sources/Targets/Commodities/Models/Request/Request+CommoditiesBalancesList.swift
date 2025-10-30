//
//  Request+CommoditiesBalancesList.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.07.2025.
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

// MARK: - CommoditiesBalancesList
extension RequestModels {
    public struct CommoditiesBalancesList: Encodable {
        public let search: String?
        public let groupId: String?
        public let commodityId: String?
        public let pageData: PaginationRequest

        public static func initial(
            search: String? = nil,
            groupId: String? = nil,
            commodityId: String? = nil
        ) -> Self {
            .init(
                search: search,
                groupId: groupId,
                commodityId: commodityId,
                pageData: .initial
            )
        }

        public init(
            search: String? = nil,
            groupId: String? = nil,
            commodityId: String? = nil,
            pageData: PaginationRequest
        ) {
            self.search = search
            self.groupId = groupId
            self.commodityId = commodityId
            self.pageData = pageData
        }

        public enum CodingKeys: String, CodingKey {
            case search
            case groupId
            case commodityId
            case page
            case pageSize
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(self.search, forKey: .search)
            try container.encodeIfPresent(self.groupId, forKey: .groupId)
            try container.encodeIfPresent(self.commodityId, forKey: .commodityId)
            try container.encode(pageData.page, forKey: .page)
            try container.encode(pageData.pageSize, forKey: .pageSize)
        }
    }
}
