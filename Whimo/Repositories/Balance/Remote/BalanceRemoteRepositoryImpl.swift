//
//  BalanceRemoteRepositoryImpl.swift
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
import RestClient
import Targets
import Utility

// MARK: - BalanceRemoteRepositoryImpl
final class BalanceRemoteRepositoryImpl: BalanceRemoteRepository {
    // MARK: - Dependencies
    private let commoditiesTarget: CommoditiesTarget
    private let commodityBalanceMapper: CommodityBalanceMapperProtocol

    // MARK: - Init
    init(
        commoditiesTarget: CommoditiesTarget,
        commodityBalanceMapper: CommodityBalanceMapperProtocol
    ) {
        self.commoditiesTarget = commoditiesTarget
        self.commodityBalanceMapper = commodityBalanceMapper
    }

    // MARK: - BalanceRemoteRepository
    func fetchCommodityBalanceList(_ pagination: BalancePagination) async throws -> IdentifiedArrayOf<CommodityBalanceModel> {
        let response = try await commoditiesTarget.commoditiesBalancesList(pagination)
        let commodityBalance = response.data.map(commodityBalanceMapper.toDomain)
        return .init(uniqueElements: commodityBalance)
    }

    func fetchCommodityBalance(commodityId: String) async throws -> IdentifiedArrayOf<CommodityBalanceModel> {
        let request: RequestModels.CommoditiesBalancesList = .initial(commodityId: commodityId)
        let response = try await commoditiesTarget.commoditiesBalancesList(request)
        let commodityBalance = response.data.map(commodityBalanceMapper.toDomain)
        return .init(uniqueElements: commodityBalance)
    }
}
