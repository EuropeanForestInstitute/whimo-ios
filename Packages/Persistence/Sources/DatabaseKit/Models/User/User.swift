//
//  User.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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

// MARK: - User
public struct User: Identifiable, Equatable {
    public static let kOfflineModeRecipientName = "Offline_Recipient"

    public var id: String
    public var username: String
    public var gadgets: [Gadget]

    public init(
        id: String,
        username: String,
        gadgets: [Gadget]
    ) {
        self.id = id
        self.username = username
        self.gadgets = gadgets
    }
}

// MARK: - User+Record
extension User: StorePersistable {
    public static var databaseTableName: String { "user" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let username = Column(CodingKeys.username)
        public static let gadgets = Column(CodingKeys.gadgets)
    }
}

// MARK: - User+Associations
extension User {
    public static let soldTransactions = hasMany(
        Transaction.self,
        using: Transaction.sellerForeignKey
    )
    public var soldtransactions: QueryInterfaceRequest<Transaction> {
        request(for: User.soldTransactions)
    }

    public static let boughtTransactions = hasMany(
        Transaction.self,
        using: Transaction.buyerForeignKey
    )
    public var boughtTransactions: QueryInterfaceRequest<Transaction> {
        request(for: User.boughtTransactions)
    }
}

// MARK: - Gadget
extension User {
    public struct Gadget: StoreConvertible, Equatable {
        public var id: String
        public var identifier: String
        public var type: GadgetType
        public var isVerified: Bool

        public init(id: String, identifier: String, type: GadgetType, isVerified: Bool) {
            self.id = id
            self.identifier = identifier
            self.type = type
            self.isVerified = isVerified
        }
    }
}

// MARK: - GadgetType
extension User.Gadget {
    public enum GadgetType: String, StoreConvertible, Equatable {
        case email = "email"
        case phone = "phone"
    }
}
