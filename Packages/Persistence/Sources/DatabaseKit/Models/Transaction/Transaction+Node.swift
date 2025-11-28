//
//  Transaction+Node.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 08.06.2025.
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

// MARK: - Node
extension Transaction {
    public struct Node: StoreCodable, Equatable {
        public var transaction: Transaction
        public var commodity: Commodity.Node
        public var seller: User?
        public var buyer: User?

        public init(
            transaction: Transaction,
            commodity: Commodity.Node,
            seller: User? = nil,
            buyer: User? = nil
        ) {
            self.transaction = transaction
            self.commodity = commodity
            self.seller = seller
            self.buyer = buyer
        }

        public static func all() -> QueryInterfaceRequest<Self> {
            Transaction
                .all()
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
                .asRequest(of: Self.self)
        }

        public static func filter(
            searchText: String,
            action: String? = nil,
            dateFrom: String? = nil,
            dateTo: String? = nil,
            refersTo userId: String? = nil
        ) -> QueryInterfaceRequest<Self> {
            Transaction
                .all()
                .including(
                    required: Transaction.commodity
                        .filter { table in
                            table.name.like("%\(searchText)%")
                        }
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
                .filter { table in
                    var exp: [SQLExpression] = []

                    if let action {
                        exp.append(table.action == action)
                    } else {
                        let allActionsExp = [
                            table.action == Transaction.Action.buy.rawValue,
                            table.action == Transaction.Action.sell.rawValue,
                        ]
                        exp.append(allActionsExp.joined(operator: .or))
                    }

                    if let dateFrom {
                        exp.append(table.createdAt >= dateFrom)
                    }
                    if let dateTo {
                        exp.append(table.createdAt <= dateTo)
                    }

                    if let userId {
                        let userIdExp = [
                            table.sellerId == userId,
                            table.buyerId == userId
                        ]

                        exp.append(userIdExp.joined(operator: .or))
                    }

                    return exp.joined(operator: .and)
                }
                .order(\.createdAt.desc)
                .asRequest(of: Self.self)
        }

        public static func allOnDisk() -> QueryInterfaceRequest<Self> {
            Transaction
                .all()
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
                .filter { table in
                    table.persistingData.like(#"%"state":{"onDisk":{}}%"#)
                }
                .order(\.createdAt.asc)
                .asRequest(of: Self.self)
        }
    }
}
