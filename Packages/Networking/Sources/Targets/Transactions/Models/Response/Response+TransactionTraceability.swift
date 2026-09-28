//
//  Response+TransactionTraceability.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.06.2025.
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
    // MARK: - TransactionTraceabilityInfo
    public struct TransactionTraceabilityInfo: AnyDataResponse {
        public let data: TransactionTraceability

        public init(data: TransactionTraceability) {
            self.data = data
        }
    }

    // MARK: - TransactionTraceability
    public struct TransactionTraceability: Decodable {
        public let items: [Traceability]

        public init(items: [Traceability]) {
            self.items = items
        }

        private enum CodingKeys: String, CodingKey {
            case counts
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let nestedContainer = try container.nestedContainer(keyedBy: ResponseModels.TransactionTraceability.Traceability.CodingKeys.self, forKey: .counts)
            var items: [Traceability] = []

            if let value = try nestedContainer.decodeIfPresent(Double.self, forKey: .full) {
                items.append(.full(value))
            }
            if let value = try nestedContainer.decodeIfPresent(Double.self, forKey: .partial) {
                items.append(.partial(value))
            }
            if let value = try nestedContainer.decodeIfPresent(Double.self, forKey: .conditional) {
                items.append(.conditional(value))
            }
            if let value = try nestedContainer.decodeIfPresent(Double.self, forKey: .incomplete) {
                items.append(.incomplete(value))
            }

            self.items = items
        }
    }
}

// MARK: - Traceability
extension ResponseModels.TransactionTraceability {
    public enum Traceability: Decodable {
        case full(Double)
        case partial(Double)
        case conditional(Double)
        case incomplete(Double)

        public enum CodingKeys: CodingKey {
            case full
            case partial
            case conditional
            case incomplete
        }
    }
}
