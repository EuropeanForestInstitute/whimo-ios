//
//  Request+MakeConversion.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.11.2025.
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

// MARK: - MakeConversion
extension RequestModels {
    public struct MakeConversion: Encodable {
        public let recipeId: String
        public let inputOverrides: [Override]
        public let outputOverrides: [Override]

        public init(
            recipeId: String,
            inputOverrides: [Override],
            outputOverrides: [Override]
        ) {
            self.recipeId = recipeId
            self.inputOverrides = inputOverrides
            self.outputOverrides = outputOverrides
        }
    }
}

// MARK: - Override
extension RequestModels.MakeConversion {
    public struct Override: Encodable {
        public let commodityId: String
        public let quantity: Double

        public init(commodityId: String, quantity: Double) {
            self.commodityId = commodityId
            self.quantity = quantity
        }
    }
}
