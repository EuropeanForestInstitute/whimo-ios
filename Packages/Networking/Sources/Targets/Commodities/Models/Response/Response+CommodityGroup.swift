//
//  Response+CommodityGroup.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.05.2025.
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

extension ResponseModels {
    // MARK: - CommodityGroupInfo
    public struct CommodityGroupInfo: AnyDataResponse {
        public let data: [CommodityGroup]

        public init(data: [CommodityGroup]) {
            self.data = data
        }
    }

    // MARK: - CommodityGroup
    public struct CommodityGroup: Decodable {
        public let id: String
        public let name: String
        public let commodities: [Commodity]

        public init(id: String, name: String, commodities: [Commodity]) {
            self.id = id
            self.name = name
            self.commodities = commodities
        }
    }
}

// MARK: - Commodity
extension ResponseModels.CommodityGroup {
    public struct Commodity: Decodable {
        public let id: String
        public let code: String
        public let name: String
        public let unit: String
        public let balance: Double?

        public init(id: String, code: String, name: String, unit: String, balance: Double?) {
            self.id = id
            self.code = code
            self.name = name
            self.unit = unit
            self.balance = balance
        }
    }
}
