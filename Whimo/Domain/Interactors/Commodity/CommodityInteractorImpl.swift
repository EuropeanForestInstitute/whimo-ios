//
//  CommodityInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.07.2025.
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
import Utility

final class CommodityInteractorImpl: CommodityInteractor {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let dataFetcherInteractor: DataFetcherInteractor
    private let commodityRepository: CommodityCachingRepository
    private let seasonRepository: SeasonCatalogueRepository
    private let balanceRepository: SeasonalBalanceRepository
    private let accountId: () -> String?

    // MARK: - Init
    init(
        dataFetcherInteractor: DataFetcherInteractor,
        commodityRepository: CommodityCachingRepository,
        seasonRepository: SeasonCatalogueRepository,
        balanceRepository: SeasonalBalanceRepository,
        accountId: @escaping () -> String?,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.dataFetcherInteractor = dataFetcherInteractor
        self.commodityRepository = commodityRepository
        self.seasonRepository = seasonRepository
        self.balanceRepository = balanceRepository
        self.accountId = accountId
    }

    // MARK: - CommodityInteractor
    func fetchCommodityGroups() async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        try await businessDataContext.withCurrentGeneration {
            guard let participant = accountId(), !participant.isEmpty else { throw CancellationError() }

            let commodityGroups = try await commodityRepository.fetchCommodityGroups()
            try Task.checkCancellation()
            await dataFetcherInteractor.startCataloguePreparation()
            var groups: IdentifiedArrayOf<CommodityGroupModel> = []
            for group in commodityGroups {
                var commodities: [CommodityGroupModel.Commodity] = []
                for commodity in group.commodities {
                    let balance = try await activeBalance(commodityId: commodity.id)
                    commodities.append(.init(id: commodity.id, code: commodity.code, name: commodity.name, unit: commodity.unit,
                        balance: balance, hasRecipe: commodity.hasRecipe, group: commodity.group))
                }
                groups.append(.init(id: group.id, name: group.name, commodities: commodities))
            }
            try Task.checkCancellation()
            guard accountId() == participant else { throw CancellationError() }

            return groups
        }
    }
    private func activeBalance(commodityId: String) async throws -> Double? {
        do {
            let seasons = try await seasonRepository.cachedSeasons(commodityId: commodityId)
            guard let active = seasons.first(where: { $0.status == .active }) else { return nil }

            return try await balanceRepository.cachedExact(commodityId: commodityId, seasonId: active.id).volume
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }
}
