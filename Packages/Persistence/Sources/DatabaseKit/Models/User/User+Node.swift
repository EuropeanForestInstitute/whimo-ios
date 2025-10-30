//
//  User+Node.swift
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

extension User {
    public struct Node: StoreDecodable, Equatable {
        public var user: User
        public var soldTransactions: [Transaction.Node]
        public var boughtTransactions: [Transaction.Node]
        public var transactions: [Transaction.Node] {
            soldTransactions + boughtTransactions
        }

        public static func all() -> QueryInterfaceRequest<Self> {
            User
                .all()
                .including(
                    all: User.soldTransactions
                    .forKey("soldTransactions")
                    .including(
                        required: Transaction.commodity
                            .forKey("commodity")
                            .including(
                                required: Commodity.group
                                    .forKey("group")
                            )
                    )
                    .including(
                        optional: Transaction.seller
                            .forKey("seller")
                    )
                    .including(
                        optional: Transaction.buyer
                            .forKey("buyer")
                    )
                    .order(\.createdAt.desc)
                )
                .including(
                    all: User.boughtTransactions
                    .forKey("boughtTransactions")
                    .including(
                        required: Transaction.commodity
                            .forKey("commodity")
                            .including(
                                required: Commodity.group
                                    .forKey("group")
                            )
                    )
                    .including(
                        optional: Transaction.seller
                            .forKey("seller")
                    )
                    .including(
                        optional: Transaction.buyer
                            .forKey("buyer")
                    )
                    .order(\.createdAt.desc)
                )
                .asRequest(of: Self.self)
        }
    }
}
