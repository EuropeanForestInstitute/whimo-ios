//
//  SellerVolumeTests.swift
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
import CommonUI
@testable import Whimo

@MainActor
final class SellerVolumeTests: XCTestCase {
    func testFormReturnRefreshesTheConfirmedSale() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let season = HarvestSeason(id: "active", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .active)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(volume: 800) }.scope(.unique)
        state.createTransaction.dispatch {
            $0.commodityType = BuyerVolumeTests.commodity
            $0.volumeAmount = "1200"
            $0.seasonSelection = .init(commodityId: "beans", season: season)
            $0.confirmedBalance = .init(commodityId: "beans", seasonId: "active",
                balance: .init(volume: 500, traceability: nil, isCached: false))
        }
        let form = CreateTransactionFormModule.ViewModel(transactionType: .downstream(action: .sell, recipient: .empty))
        await drainFormUpdates()
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "700")
        await form.refreshBalance()
        await drainFormUpdates()
        XCTAssertEqual(form.volumeBreakdown?.seasonVolume, "800")
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "400")
        XCTAssertEqual(form.volumeAmount, "1200")
        XCTAssertEqual(form.volumeSeason, season)
    }

    func testConfirmationSuppliesExactCachedBreakdownToSellerForm() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(volume: 500) }.scope(.unique)
        let form = CreateTransactionFormModule.ViewModel(transactionType: .downstream(action: .sell, recipient: .empty))
        let editor = makeModel(volume: "1200")
        await editor.loadSeasons()
        await editor.loadBalance()
        editor.didTapConfirm()
        let updated = expectation(description: "Confirmed preview reaches form")
        let subscription = form.$confirmedBalance.compactMap { $0 }.first().sink { _ in updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
        let breakdown = try XCTUnwrap(form.volumeBreakdown)
        XCTAssertEqual(breakdown.seasonVolume, "500")
        XCTAssertEqual(breakdown.automaticVolume, "700")
        XCTAssertEqual(form.confirmedBalance?.commodityId, "beans")
        XCTAssertEqual(form.confirmedBalance?.seasonId, "active")
        XCTAssertEqual(form.confirmedBalance?.balance.isCached, true)
        XCTAssertEqual(state.createTransaction.value.volumeAmount, "1200")
        withExtendedLifetime(subscription) {}
    }

    func testBreakdownQuantitiesAndFormattingPreserveFractionsAndZero() throws {
        let season = HarvestSeason(id: "active", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .active)
        let cases: [(String, Double, String, String)] = [
            ("1200", 1500, "1200", "0"), ("1200", 1200, "1200", "0"),
            ("1000", 0.0001, "0.0001", "999.9999"), ("0001.2000", 0.5, "0.5", "0.7"),
            ("1200", 500, "500", "700"), ("1200", 0, "0", "1200"),
            ("1.0000000000000000000000000000000000000001", 1, "1", "0.0000000000000000000000000000000000000001"),
            ("0", 0, "0", "0"), ("0.3", 0.1, "0.1", "0.2"),
            ("1", 0.9999, "0.9999", "0.0001"), ("1.2000", 0.5, "0.5", "0.7"),
            ("0.00000000000000000001", 0, "0", "0.00000000000000000001")
        ]
        for (input, available, covered, automatic) in cases {
            let breakdown = try XCTUnwrap(SaleVolumeBreakdown(volume: input, season: season,
                balance: .init(volume: available, traceability: nil, isCached: false)))
            XCTAssertEqual(breakdown.seasonVolume, covered)
            XCTAssertEqual(breakdown.automaticVolume, automatic)
            XCTAssertEqual(CreateTransactionFormModule.volumeDescription(
                breakdown.seasonVolume, unit: "kg", locale: Locale(identifier: "en")), covered + " kg")
            XCTAssertEqual(CreateTransactionFormModule.volumeDescription(
                breakdown.automaticVolume, unit: "kg", locale: Locale(identifier: "en")), automatic + " kg")
            XCTAssertEqual(CreateTransactionFormModule.volumeDescription(
                breakdown.automaticVolume, unit: "kg", locale: Locale(identifier: "fr")),
                automatic.replacingOccurrences(of: ".", with: ",") + " kg")
        }
        for input in ["", "nan", "inf", "-1", "invalid"] {
            XCTAssertNil(SaleVolumeBreakdown(volume: input, season: season, balance: .init(volume: 500, traceability: nil, isCached: false)))
        }
    }

    func testOnlyActiveCanIncludeAutomaticAndZeroRetainsSeasonRow() throws {
        for status in [HarvestSeasonStatus.active, .past, .archive] {
            let season = HarvestSeason(id: "season", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: status)
            let balance = ExactSeasonalBalance(volume: 500, traceability: nil, isCached: false)
            let covered = try XCTUnwrap(SaleVolumeBreakdown(volume: "500", season: season, balance: balance))
            XCTAssertTrue(covered.showsSeason)
            XCTAssertFalse(covered.showsAutomatic)
            let zero = try XCTUnwrap(SaleVolumeBreakdown(volume: "0", season: season, balance: balance))
            XCTAssertTrue(zero.showsSeason)
            XCTAssertFalse(zero.showsAutomatic)
            let shortage = SaleVolumeBreakdown(volume: "1200", season: season, balance: balance)
            XCTAssertEqual(shortage?.showsAutomatic, status == .active ? true : nil)
            let empty = SaleVolumeBreakdown(volume: "1200", season: season,
                balance: .init(volume: 0, traceability: nil, isCached: false))
            XCTAssertEqual(empty?.showsSeason, status == .active ? false : nil)
        }
    }

    func testFormDistinguishesMissingBalanceFromZeroAndRejectsOtherPairs() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let season = HarvestSeason(id: "active", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .active)
        AppContainer.shared.appState.register { state }.scope(.unique)
        let form = CreateTransactionFormModule.ViewModel(transactionType: .downstream(action: .sell, recipient: .empty))
        state.createTransaction.dispatch {
            $0.commodityType = BuyerVolumeTests.commodity
            $0.volumeAmount = "1200"
            $0.seasonSelection = .init(commodityId: "beans", season: season)
        }
        await drainFormUpdates()
        XCTAssertNil(form.volumeBreakdown)
        XCTAssertNotNil(form.volumeSeason)
        state.createTransaction[\.confirmedBalance] = .init(commodityId: "beans", seasonId: "active",
            balance: .init(volume: 0, traceability: nil, isCached: false))
        await drainFormUpdates()
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "1200")
        state.createTransaction[\.confirmedBalance] = .init(commodityId: "other", seasonId: "active",
            balance: .init(volume: 0, traceability: nil, isCached: false))
        await drainFormUpdates()
        XCTAssertNil(form.volumeBreakdown)
        state.createTransaction[\.confirmedBalance] = .init(commodityId: "beans", seasonId: "other",
            balance: .init(volume: 0, traceability: nil, isCached: false))
        await drainFormUpdates()
        XCTAssertNil(form.volumeBreakdown)
        state.createTransaction[\.commodityType] = .initialState
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        XCTAssertNil(state.createTransaction.value.confirmedBalance)
        state.createTransaction[\.seasonSelection] = nil
        await drainFormUpdates()
        XCTAssertNil(form.volumeSeason)
        XCTAssertNil(form.volumeBreakdown)
    }

    func testPopupAndEditorAreIndependentAndBuyerNeverShowsAutomatic() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let alerts = AlertManager()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(volume: 0) }.scope(.unique)
        let form = CreateTransactionFormModule.ViewModel(transactionType: .downstream(action: .sell, recipient: .empty))
        let editor = makeModel(volume: "1200")
        await editor.loadSeasons()
        await editor.loadBalance()
        editor.didTapConfirm()
        await drainFormUpdates()
        let draft = state.createTransaction.value
        let routes = state.navigation.value.path
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "1200")
        form.didTapAutomaticInfo()
        await drainFormUpdates()
        XCTAssertEqual(state.navigation.value.path, routes)
        alerts.close()
        await drainFormUpdates()
        XCTAssertEqual(state.createTransaction.value, draft)
        form.didTapOpenCommodityVolumeScreen()
        XCTAssertEqual(state.navigation.value.path.count, routes.count + 1)
        state.createTransaction[\.transactionType] = .downstream(action: .buy, recipient: .empty)
        await drainFormUpdates()
        XCTAssertNil(form.volumeBreakdown)
        XCTAssertNotNil(form.volumeSeason)
        XCTAssertEqual(form.volumeAmount, "1200")
    }

    private func drainFormUpdates() async {
        let updated = expectation(description: "Main queue form state delivery")
        DispatchQueue.main.async { updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
    }

    func testPastShortageBlocksConfirmAndDoesNotCommitDraft() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let commodity = BuyerVolumeTests.commodity
        state.createTransaction[\.commodityType] = commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble() }.scope(.unique)
        let model = CommodityVolumeModule.ViewModel(volumeAmount: "300", commodityType: commodity,
            transactionType: .downstream(action: .sell, recipient: .empty))
        await model.loadSeasons()
        if let past = model.seasons.first(where: { $0.status == .past }) { model.selectSeason(past) }
        await model.loadBalance()
        XCTAssertEqual(model.selectedSeason?.id, "past")
        XCTAssertFalse(model.canConfirm)
        model.didTapConfirm()
        XCTAssertTrue(state.createTransaction.value.volumeAmount.isEmpty)
        XCTAssertNil(state.createTransaction.value.seasonSelection)
    }
    func testEveryStatusWithEnoughExactAndInsufficientBalanceRecoversImmediately() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble() }.scope(.unique)
        let model = makeModel()
        await model.loadSeasons()
        XCTAssertEqual(model.selectedSeason?.status, .active)
        for season in model.seasons {
            model.selectSeason(season)
            XCTAssertFalse(model.canConfirm, "Old season balance cannot authorize a newly selected season")
            await model.loadBalance()
            for quantity in ["59", "60"] {
                model.volumeText = quantity
                XCTAssertTrue(model.canConfirm)
                XCTAssertFalse(model.hasSeasonalShortage)
                XCTAssertFalse(model.enableNoteBanner)
            }
            model.volumeText = "61"
            XCTAssertEqual(model.canConfirm, season.status == .active)
            XCTAssertEqual(model.enableNoteBanner, season.status == .active)
            XCTAssertEqual(model.hasSeasonalShortage, season.status != .active)
            model.volumeText = "60"
            XCTAssertTrue(model.canConfirm)
            XCTAssertFalse(model.hasSeasonalShortage)
            model.didTapConfirm()
            XCTAssertEqual(state.createTransaction.value.volumeAmount, "60")
            XCTAssertEqual(state.createTransaction.value.seasonSelection?.season.id, season.id)
        }
        let reopened = makeModel(volume: state.createTransaction.value.volumeAmount)
        await reopened.loadSeasons()
        await reopened.loadBalance()
        XCTAssertEqual(reopened.selectedSeason?.status, .archive)
        XCTAssertTrue(reopened.canConfirm)
    }

    func testCancelledBalanceLookupDoesNotPermitConfirmation() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(cancelled: true) }.scope(.unique)
        let model = makeModel()
        await model.loadSeasons()
        await model.loadBalance()
        XCTAssertFalse(model.balanceUnavailable)
        XCTAssertFalse(model.canConfirm)
        model.didTapConfirm()
        XCTAssertNil(state.createTransaction.value.seasonSelection)
    }

    func testUnknownAndKnownZeroBalanceAndInvalidQuantitiesStayDistinct() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        for balance in [nil, Double(0)] {
            AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(volume: balance) }.scope(.unique)
            let model = makeModel()
            await model.loadSeasons()
            for season in model.seasons {
                model.selectSeason(season)
                await model.loadBalance()
                XCTAssertEqual(model.balanceUnavailable, balance == nil)
                XCTAssertEqual(model.canConfirm, balance == nil || season.status == .active)
                XCTAssertEqual(model.enableNoteBanner, balance != nil && season.status == .active)
                XCTAssertEqual(model.hasSeasonalShortage, balance != nil && season.status != .active)
                for input in ["", "-1", "nan", "inf", "invalid"] {
                    model.volumeText = input
                    XCTAssertFalse(model.canConfirm)
                }
                model.volumeText = "300"
            }
        }
    }

    func testObsoleteBalanceCannotReturnAfterSeasonChangesAwayAndBack() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        let controlled = ControlledSellerBalance()
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { controlled }.scope(.unique)
        let model = makeModel()
        await model.loadSeasons()
        let active = try XCTUnwrap(model.selectedSeason)
        let oldLoad = Task { await model.loadBalance() }
        await controlled.waitForCall()
        model.selectSeason(try XCTUnwrap(model.seasons.first(where: { $0.status == .past })))
        model.selectSeason(active)
        await controlled.complete()
        await oldLoad.value
        XCTAssertNil(model.seasonalBalance)
        XCTAssertFalse(model.canConfirm)
        XCTAssertFalse(model.enableNoteBanner)
    }

    func testChangingCommodityImmediatelyRejectsOldBalanceAndRevalidatesThePair() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble() }.scope(.unique)
        let model = makeModel(volume: "60")
        await model.loadSeasons()
        await model.loadBalance()
        XCTAssertTrue(model.canConfirm)
        let other = CommodityGroupModel.Commodity(id: "butter", code: "1804", name: "Butter", unit: "kg", balance: 2000,
            hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
        let changed = expectation(description: "Commodity updated")
        let subscription = model.$commodityType.filter { $0.id == "butter" }.first().sink { _ in changed.fulfill() }
        state.createTransaction[\.commodityType] = other
        model.didTapConfirm()
        XCTAssertNil(state.createTransaction.value.seasonSelection)
        await fulfillment(of: [changed], timeout: 2)
        XCTAssertNil(model.seasonalBalance)
        XCTAssertFalse(model.canConfirm)
        await model.loadSeasons()
        await model.loadBalance()
        XCTAssertEqual(model.volumeText, "60")
        model.didTapConfirm()
        XCTAssertEqual(state.createTransaction.value.seasonSelection?.commodityId, "butter")
        withExtendedLifetime(subscription) {}
    }

    func testMissingCatalogueBlocksSellingWithNoGuessedSeason() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { SellerSeasonsDouble(missing: true) }.scope(.unique)
        let model = makeModel()
        await model.loadSeasons()
        XCTAssertTrue(model.catalogueUnavailable)
        XCTAssertNil(model.selectedSeason)
        XCTAssertFalse(model.canConfirm)
        model.didTapConfirm()
        XCTAssertNil(state.createTransaction.value.seasonSelection)
    }

    private func makeModel(volume: String = "300") -> CommodityVolumeModule.ViewModel {
        .init(volumeAmount: volume, commodityType: BuyerVolumeTests.commodity,
              transactionType: .downstream(action: .sell, recipient: .empty))
    }

}

private struct SellerSeasonsDouble: CreationSeasonInteractor {
    var volume: Double? = 60
    var missing = false
    var cancelled = false
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        if missing { throw CreationSeasonError.catalogueRequired }
        return .init(values: [HarvestSeasonStatus.active, .past, .archive].map {
            .init(id: $0 == .active ? "active" : $0 == .past ? "past" : "archived", name: "Season",
                startDate: .distantPast, endDate: .distantFuture, status: $0)
        }, isCached: true)
    }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        try XCTUnwrap(selection?.season)
    }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        if cancelled { throw CancellationError() }
        guard let volume else { throw SeasonalBalanceError.incompleteResponse }
        return .init(volume: volume, traceability: nil, isCached: true)
    }
}

private actor ControlledSellerBalance: CreationSeasonInteractor {
    private var pending: CheckedContinuation<ExactSeasonalBalance, Never>?
    private var waiter: CheckedContinuation<Void, Never>?
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        try await SellerSeasonsDouble().seasons(commodityId: commodityId)
    }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        try XCTUnwrap(selection?.season)
    }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        await withCheckedContinuation {
            pending = $0
            waiter?.resume()
            waiter = nil
        }
    }
    func waitForCall() async {
        if pending != nil { return }
        await withCheckedContinuation { waiter = $0 }
    }
    func complete() {
        pending?.resume(returning: .init(volume: 2000, traceability: nil, isCached: false))
        pending = nil
    }
}
