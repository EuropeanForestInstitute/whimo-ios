//
//  Commodity.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 31.05.2025.
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

// MARK: - Commodity
public struct Commodity: Identifiable, Equatable {
    public var id: String
    public var code: String
    public var name: String
    public var unit: String
    public let balance: Double?
    public var commodityGroupId: String?
    public var hasRecipe: Bool

    public init(
        id: String,
        code: String,
        name: String,
        unit: String,
        balance: Double?,
        commodityGroupId: String?,
        hasRecipe: Bool
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.unit = unit
        self.balance = balance
        self.commodityGroupId = commodityGroupId
        self.hasRecipe = hasRecipe
    }
}

// MARK: - Commodity+Record
extension Commodity: StorePersistable {
    public static var databaseTableName: String { "commodity" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let code = Column(CodingKeys.code)
        public static let name = Column(CodingKeys.name)
        public static let unit = Column(CodingKeys.unit)
        public static let balance = Column(CodingKeys.balance)
        public static let commodityGroupId = Column(CodingKeys.commodityGroupId)
        public static let hasRecipe = Column(CodingKeys.hasRecipe)
    }
}

// MARK: - Commodity+Associations
extension Commodity {
    public static let group = belongsTo(CommodityGroup.self)
    public var group: QueryInterfaceRequest<CommodityGroup> {
        request(for: Commodity.group)
    }
}
