//
//  CreationSeasonTests.swift
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

import XCTest
@testable import Whimo

final class CreationSeasonTests: XCTestCase {
    func testFinalValidationAcceptsEveryCoveredStatusWithoutReadingOwnBalance() async throws {
        for status in [HarvestSeasonStatus.active, .past, .archive] {
            let season = HarvestSeason(id: "captured", name: "Backend name", startDate: .distantPast, endDate: .distantFuture, status: status)
            let interactor = CreationSeasonInteractorImpl(catalogue: CreationCatalogue(seasons: [season]), balances: UnusedCreationBalance())
            let captured = CreationSeason(commodityId: "beans", season: season)
            let validated = try await interactor.validate(captured, commodityId: "beans")
            XCTAssertEqual(validated.id, "captured")
            XCTAssertEqual(validated.status, status)
            do {
                _ = try await interactor.validate(captured, commodityId: "butter")
                XCTFail("A changed commodity requires coverage validation")
            } catch CreationSeasonError.invalidSelection { }
        }
    }

    func testFinalValidationCannotChooseActiveForMissingOrNoLongerCoveredDraft() async throws {
        let season = HarvestSeason(id: "new-active", name: "New", startDate: .distantPast, endDate: .distantFuture, status: .active)
        let interactor = CreationSeasonInteractorImpl(catalogue: CreationCatalogue(seasons: [season]), balances: UnusedCreationBalance())
        let old = HarvestSeason(id: "old", name: "Old", startDate: .distantPast, endDate: .distantFuture, status: .past)
        for selection in [nil, CreationSeason(commodityId: "beans", season: old)] {
            do {
                _ = try await interactor.validate(selection, commodityId: "beans")
                XCTFail("Submission must never substitute a season")
            } catch CreationSeasonError.invalidSelection { }
        }
        let empty = CreationSeasonInteractorImpl(catalogue: CreationCatalogue(seasons: []), balances: UnusedCreationBalance())
        do {
            _ = try await empty.seasons(commodityId: "beans")
            XCTFail("An empty catalogue requires the connection explanation")
        } catch CreationSeasonError.catalogueRequired { }
    }
}

private struct CreationCatalogue: SeasonCatalogueRepository {
    let seasons: [HarvestSeason]
    func cachedSeasons(commodityId: String) async throws -> [HarvestSeason] {
        try await seasons(commodityId: commodityId).values
    }
    func groups() async throws -> CatalogueResult<CatalogueGroup> { throw CreationSeasonError.invalidSelection }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> { throw CreationSeasonError.invalidSelection }
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        .init(values: seasons, isCached: true)
    }
}

private struct UnusedCreationBalance: SeasonalBalanceRepository {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        XCTFail("Buy validation must not query or limit own balance")
        throw SeasonalBalanceError.unavailableCache
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
}
