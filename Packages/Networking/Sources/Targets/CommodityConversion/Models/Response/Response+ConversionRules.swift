//
//  Response+ConversionRules.swift
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

extension ResponseModels {
    // MARK: - ConversionRules
    public struct ConversionRules: AnyPaginationDataResponse {
        public let data: [Rule]
        public let pagination: Pagination

        public init(data: [Rule], pagination: Pagination) {
            self.data = data
            self.pagination = pagination
        }
    }

    // MARK: - Rule
    public struct Rule: Decodable {
        public let id: String
        public let name: String
        public let inputs: [RuleItem]
        public let outputs: [RuleItem]

        public init(id: String, name: String, inputs: [RuleItem], outputs: [RuleItem]) {
            self.id = id
            self.name = name
            self.inputs = inputs
            self.outputs = outputs
        }
    }
}

// MARK: - RuleItem
extension ResponseModels.Rule {
    public struct RuleItem: Decodable {
        public let id: String
        public let commodity: ResponseModels.CommodityGroup.Commodity
        public let quantity: Double

        public init(id: String, commodity: ResponseModels.CommodityGroup.Commodity, quantity: Double) {
            self.id = id
            self.commodity = commodity
            self.quantity = quantity
        }
    }
}
