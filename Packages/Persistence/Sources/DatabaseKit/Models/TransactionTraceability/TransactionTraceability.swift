//
//  TransactionTraceability.swift
//  Database
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
import GRDB

// MARK: - TransactionTraceability
public struct TransactionTraceability: Identifiable {
    public var id: Int64?
    public var items: [Traceability]
    public var transactionId: String?

    public init(
        id: Int64? = nil,
        items: [Traceability],
        transactionId: String?
    ) {
        self.id = id
        self.items = items
        self.transactionId = transactionId
    }
}

// MARK: - TransactionTraceability+Record
extension TransactionTraceability: MutableStorePersistable {
    public static var databaseTableName: String { "transactionTraceability" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let items = Column(CodingKeys.items)
    }
}

// MARK: - TransactionTraceability+Associations
extension TransactionTraceability {
    public static let transaction = belongsTo(Transaction.self)
    public var transaction: QueryInterfaceRequest<Transaction> {
        request(for: TransactionTraceability.transaction)
    }
}

// MARK: - Traceability
extension TransactionTraceability {
    public enum Traceability: StoreConvertible {
        case full(Double)
        case partial(Double)
        case conditional(Double)
        case incomplete(Double)
    }
}
