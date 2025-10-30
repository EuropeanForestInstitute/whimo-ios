//
//  Response+CommodityBalance.swift
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

extension ResponseModels {
    // MARK: - CommodityBalanceInfo
    public struct CommodityBalanceInfo: AnyDataResponse {
        public let data: [CommodityBalance]

        public init(data: [CommodityBalance]) {
            self.data = data
        }
    }

    // MARK: - CommodityBalance
    public struct CommodityBalance: Decodable {
        public let id: String
        public let volume: Double
        public let commodity: Commodity

        public init(id: String, volume: Double, commodity: Commodity) {
            self.id = id
            self.volume = volume
            self.commodity = commodity
        }
    }
}
