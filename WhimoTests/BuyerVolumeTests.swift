//
//  BuyerVolumeTests.swift
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
import FactoryKit
import Utility
@testable import Whimo

@MainActor
final class BuyerVolumeTests: XCTestCase {
    func testEverySeasonCanConfirmAboveZeroOwnBalanceAndRetainsDraft() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let seasons = BuyerSeasonDouble()
        state.createTransaction[\.commodityType] = Self.commodity
        state.navigation[\.path] = [.push(.commoditiesList)]
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { seasons }.scope(.unique)
        let model = CommodityVolumeModule.ViewModel(volumeAmount: "300", commodityType: Self.commodity,
            transactionType: .downstream(action: .buy, recipient: .empty))
        await model.loadSeasons()
        XCTAssertEqual(model.selectedSeason?.id, "active")
        for season in seasons.values {
            model.selectSeason(season)
            await model.loadBalance()
            XCTAssertEqual(model.seasonalBalance?.volume, 0)
            XCTAssertTrue(model.canConfirm)
            XCTAssertFalse(model.enableNoteBanner)
            XCTAssertEqual(model.volumeText, "300")
        }
        model.didTapConfirm()
        XCTAssertEqual(state.createTransaction.value.seasonSelection?.season.id, "archived")
        XCTAssertEqual(state.createTransaction.value.seasonSelection?.commodityId, "beans")
        XCTAssertEqual(state.createTransaction.value.volumeAmount, "300")
    }

    func testUnavailableOwnBalanceDoesNotBlockAndMissingCatalogueDoes() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = Self.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { BuyerSeasonDouble(balanceUnavailable: true) }.scope(.unique)
        let model = CommodityVolumeModule.ViewModel(volumeAmount: "300", commodityType: Self.commodity,
            transactionType: .downstream(action: .buy, recipient: .empty))
        await model.loadSeasons()
        await model.loadBalance()
        XCTAssertNil(model.seasonalBalance)
        XCTAssertTrue(model.canConfirm)
        AppContainer.shared.creationSeasonInteractor.register { BuyerSeasonDouble(catalogueUnavailable: true) }.scope(.unique)
        let unavailable = CommodityVolumeModule.ViewModel(volumeAmount: "300", commodityType: Self.commodity,
            transactionType: .downstream(action: .buy, recipient: .empty))
        await unavailable.loadSeasons()
        XCTAssertTrue(unavailable.catalogueUnavailable)
        XCTAssertFalse(unavailable.canConfirm)
        unavailable.didTapConfirm()
        XCTAssertNil(state.createTransaction.value.seasonSelection)
    }

    func testCommodityChangeRejectsOldCatalogueAndKeepsQuantity() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let interactor = ControlledBuyerSeasons()
        state.createTransaction[\.commodityType] = Self.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { interactor }.scope(.unique)
        let model = CommodityVolumeModule.ViewModel(volumeAmount: "300", commodityType: Self.commodity,
            transactionType: .downstream(action: .buy, recipient: .empty))
        let oldLoad = Task { await model.loadSeasons() }
        let oldCall = await interactor.nextCall()
        let other = CommodityGroupModel.Commodity(id: "butter", code: "1804", name: "Butter", unit: "kg", balance: 0,
            hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
        let changed = expectation(description: "Commodity observation")
        let subscription = model.$commodityType.filter { $0.id == "butter" }.first().sink { _ in changed.fulfill() }
        state.createTransaction[\.commodityType] = other
        await fulfillment(of: [changed], timeout: 2)
        let newLoad = Task { await model.loadSeasons() }
        let newCall = await interactor.nextCall()
        await interactor.complete(newCall, seasonId: "butter-active")
        await newLoad.value
        await interactor.complete(oldCall, seasonId: "beans-active")
        await oldLoad.value
        XCTAssertEqual(model.selectedSeason?.id, "butter-active")
        XCTAssertEqual(model.volumeText, "300")
        XCTAssertTrue(model.canConfirm)
        model.selectSeason(.init(id: "foreign", name: "Foreign", startDate: .distantPast, endDate: .distantFuture, status: .past))
        XCTAssertEqual(model.selectedSeason?.id, "butter-active")
        withExtendedLifetime(subscription) {}
    }

    static let commodity = CommodityGroupModel.Commodity(id: "beans", code: "1801", name: "Cocoa beans", unit: "kg",
        balance: 0, hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
}

private struct BuyerSeasonDouble: CreationSeasonInteractor {
    var catalogueUnavailable = false
    var balanceUnavailable = false
    let values: [HarvestSeason] = [
        .init(id: "active", name: "Active", startDate: .distantPast, endDate: .distantFuture, status: .active),
        .init(id: "past", name: "Past", startDate: .distantPast, endDate: .distantFuture, status: .past),
        .init(id: "archived", name: "Archived", startDate: .distantPast, endDate: .distantFuture, status: .archive)
    ]
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        if catalogueUnavailable { throw CreationSeasonError.catalogueRequired }
        return .init(values: values, isCached: true)
    }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        try XCTUnwrap(selection?.season)
    }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        if balanceUnavailable { throw SeasonalBalanceError.unavailableCache }
        return .init(volume: 0, traceability: nil, isCached: false)
    }
}

private actor ControlledBuyerSeasons: CreationSeasonInteractor {
    private var pending: [String: CheckedContinuation<CatalogueResult<HarvestSeason>, Never>] = [:]
    private var calls: [String] = []
    private var waiter: CheckedContinuation<String, Never>?

    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        await withCheckedContinuation { continuation in
            pending[commodityId] = continuation
            if let waiter {
                self.waiter = nil
                waiter.resume(returning: commodityId)
            } else {
                calls.append(commodityId)
            }
        }
    }
    func nextCall() async -> String {
        if !calls.isEmpty { return calls.removeFirst() }
        return await withCheckedContinuation { waiter = $0 }
    }
    func complete(_ id: String, seasonId: String) {
        pending.removeValue(forKey: id)?.resume(returning: .init(values: [
            .init(id: seasonId, name: seasonId, startDate: .distantPast, endDate: .distantFuture, status: .active)
        ], isCached: false))
    }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        throw CreationSeasonError.invalidSelection
    }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        throw SeasonalBalanceError.unavailableCache
    }
}
