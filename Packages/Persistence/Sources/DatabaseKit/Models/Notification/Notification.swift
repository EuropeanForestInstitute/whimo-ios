//
//  Notification.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 24.06.2025.
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
import Utility

// MARK: - Notification
public struct Notification: Identifiable, AutoStringConvertible, Equatable {
    public var id: String
    public var createdAt: String
    public var type: NotificationType
    public var status: Status
    public var transactionNode: Transaction.Node

    public init(
        id: String,
        createdAt: String,
        type: NotificationType,
        status: Status,
        transactionNode: Transaction.Node
    ) {
        self.id = id
        self.createdAt = createdAt
        self.type = type
        self.status = status
        self.transactionNode = transactionNode
    }
}

// MARK: - Notification+Record
extension Notification: StorePersistable {
    public static var databaseTableName: String { "notification" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let createdAt = Column(CodingKeys.createdAt)
        public static let type = Column(CodingKeys.type)
        public static let status = Column(CodingKeys.status)
        public static let transactionNode = Column(CodingKeys.transactionNode)
    }
}

// MARK: - Notification+Associations
extension Notification {
    public static let transaction = belongsTo(Transaction.self)
    public var transaction: QueryInterfaceRequest<Transaction> {
        request(for: Notification.transaction)
    }
}

// MARK: - NotificationType
extension Notification {
    public enum NotificationType: String, StoreConvertible, Equatable {
        case transactionPending
        case transactionAccepted
        case transactionRejected
        case transactionExpired
        case geodataMissing
    }
}

// MARK: - Status
extension Notification {
    public enum Status: String, StoreConvertible, Equatable {
        case pending
        case read
    }
}
