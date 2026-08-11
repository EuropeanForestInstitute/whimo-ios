//
//  Request+GetConversionRules.swift
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

// MARK: - GetConversionRules
extension RequestModels {
    public struct GetConversionRules: Encodable, Equatable {
        // MARK: - Encodable Properties
        public let commodityId: String
        public let pageData: PaginationRequest

        // MARK: - Local Usage Properties
        /// Cached value. Indicates is next page reachable on BE.
        /// Only for internal usage. Do not use this property to make requests.
        public var nextPage: Int?
        public var hasNextPage: Bool { nextPage != nil }

        // MARK: - Static Methods
        public static func initial(commodityId: String) -> Self {
            .init(
                commodityId: commodityId,
                pageData: .initial
            )
        }

        // MARK: - Public Init
        public init(
            commodityId: String,
            pageData: PaginationRequest = .initial
        ) {
            self.commodityId = commodityId
            self.pageData = pageData
        }

        // MARK: - CodingKeys
        public enum CodingKeys: CodingKey {
            case commodityId
            case page
            case pageSize
        }

        // MARK: - Encodable
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(commodityId, forKey: CodingKeys.commodityId)
            try container.encode(pageData.page, forKey: CodingKeys.page)
            try container.encode(pageData.pageSize, forKey: CodingKeys.pageSize)
        }
    }
}
