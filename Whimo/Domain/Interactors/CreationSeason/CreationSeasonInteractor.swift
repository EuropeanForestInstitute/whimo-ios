//
//  CreationSeasonInteractor.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 19.08.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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

protocol CreationSeasonInteractor {
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason>
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance
}

final class CreationSeasonInteractorImpl: CreationSeasonInteractor {
    private let catalogue: SeasonCatalogueRepository
    private let balances: SeasonalBalanceRepository

    init(catalogue: SeasonCatalogueRepository, balances: SeasonalBalanceRepository) {
        self.catalogue = catalogue
        self.balances = balances
    }

    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        guard !commodityId.isEmpty else { throw CreationSeasonError.invalidSelection }

        do {
            let result = try await catalogue.seasons(commodityId: commodityId)
            guard !result.values.isEmpty else { throw CreationSeasonError.catalogueRequired }

            return result
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw CreationSeasonError.catalogueRequired
        }
    }

    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        guard let selection, selection.commodityId == commodityId else { throw CreationSeasonError.invalidSelection }

        let catalogue = try await seasons(commodityId: commodityId)
        guard let season = catalogue.values.first(where: { $0.id == selection.season.id }) else {
            throw CreationSeasonError.invalidSelection
        }
        return season
    }

    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        try await balances.exact(commodityId: commodityId, seasonId: seasonId)
    }
}
