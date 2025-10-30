//
//  BalanceLocalRepositoryImpl.swift
//  Whimo
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
import DatabaseKit
import Utility

// MARK: - BalanceLocalRepositoryImpl
final class BalanceLocalRepositoryImpl: BalanceLocalRepository {
    // MARK: - Dependencies
    private let database: DatabaseKit.Database
    private let commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol

    // MARK: - Init
    init(
        database: DatabaseKit.Database,
        commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol
    ) {
        self.database = database
        self.commoditiesGroupsMapper = commoditiesGroupsMapper
    }

    // MARK: - BalanceLocalRepository
    func fetchCommodityGroupsBalance() async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        let dbModels = try await database.readAll(DatabaseKit.CommodityGroup.Node.balanceNotNull())
        let domainModels: [CommodityGroupModel] = dbModels.map(commoditiesGroupsMapper.toDomain)

        return .init(uniqueElements: domainModels)
    }
}
