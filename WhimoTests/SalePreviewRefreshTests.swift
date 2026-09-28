//
//  SalePreviewRefreshTests.swift
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
@testable import Whimo

@MainActor
final class SalePreviewRefreshTests: XCTestCase {
    func testOverlappingReturnsRetainPreviewAndApplyLatestQuantityOnly() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = SaleRefreshFixture()
        let form = fixture.form
        await drainUpdates()
        let old = Task { await form.refreshBalance() }
        let oldCall = await fixture.balance.nextCall()
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "700")
        fixture.state.createTransaction[\.volumeAmount] = "1500"
        let latest = Task { await form.refreshBalance() }
        let latestCall = await fixture.balance.nextCall()
        XCTAssertEqual(latestCall.commodityId, "beans")
        XCTAssertEqual(latestCall.seasonId, "active")
        await fixture.balance.complete(latestCall, volume: 800)
        await latest.value
        await fixture.balance.complete(oldCall, volume: 100)
        await old.value
        await drainUpdates()
        XCTAssertEqual(form.volumeBreakdown?.seasonVolume, "800")
        XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "700")
        XCTAssertEqual(form.volumeAmount, "1500")
        XCTAssertEqual(form.transactionType, fixture.transactionType)
        XCTAssertEqual(form.farmLocation, fixture.evidence)
    }

    func testObsoleteResponsesCannotRestoreASelectionRoundTripOrClearedDraft() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        for change in ["season", "commodity", "draft"] {
            let fixture = SaleRefreshFixture()
            let form = fixture.form
            let old = Task { await form.refreshBalance() }
            let call = await fixture.balance.nextCall()
            let original = fixture.state.createTransaction.value
            fixture.state.createTransaction.dispatch {
                switch change {
                    case "season":
                        $0.seasonSelection = nil
                        $0.seasonSelection = original.seasonSelection
                    case "commodity":
                        $0.commodityType = .initialState
                        $0.commodityType = original.commodityType
                    default:
                        $0.clear()
                }
            }
            await fixture.balance.complete(call, volume: 800)
            await old.value
            await drainUpdates()
            XCTAssertNil(form.confirmedBalance, change)
            XCTAssertNil(form.volumeBreakdown, change)
            XCTAssertNil(fixture.state.createTransaction.value.confirmedBalance, change)
        }
    }

    func testFailedRefreshUsesSavedBalanceAndUnknownRecoversToKnownZero() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        for known in [nil, Double(500)] {
            let fixture = SaleRefreshFixture(knownVolume: known)
            let form = fixture.form
            XCTAssertEqual(form.volumeAmount, "1200", "The draft is available synchronously")
            let load = Task { await form.refreshBalance() }
            let call = await fixture.balance.nextCall()
            await fixture.balance.fail(call)
            await load.value
            await drainUpdates()
            if known != nil {
                XCTAssertEqual(form.volumeBreakdown?.seasonVolume, "500")
                XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "700")
                XCTAssertEqual(form.confirmedBalance?.balance.isCached, true)
                XCTAssertTrue(form.isSaveButtonEnabled)
            } else {
                XCTAssertNil(form.volumeBreakdown)
                XCTAssertNotNil(form.saleSummaryMessage)
                XCTAssertTrue(form.isSaveButtonEnabled, "Unknown balance permits sale without inventing a breakdown")
            }
            let recovery = Task { await form.refreshBalance() }
            let recoveryCall = await fixture.balance.nextCall()
            await fixture.balance.complete(recoveryCall, volume: 0)
            await recovery.value
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "1200")
            XCTAssertFalse(try XCTUnwrap(form.volumeBreakdown).showsSeason)
            XCTAssertEqual(form.confirmedBalance?.balance.isCached, false)
            XCTAssertNil(form.saleSummaryMessage)
            XCTAssertTrue(form.isSaveButtonEnabled)
            fixture.state.createTransaction[\.volumeAmount] = "0.00001"
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "0.00001")
            fixture.state.createTransaction[\.volumeAmount] = "0"
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.seasonVolume, "0")
            XCTAssertFalse(try XCTUnwrap(form.volumeBreakdown).showsAutomatic)
        }
    }

    func testRefreshedMetadataKeepsSeasonIdentityAndBlocksNonActiveShortage() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        for status in [HarvestSeasonStatus.past, .archive] {
            let fixture = SaleRefreshFixture()
            let form = fixture.form
            await fixture.balance.setStatus(status)
            let refresh = Task { await form.refreshBalance() }
            let call = await fixture.balance.nextCall()
            await fixture.balance.complete(call, volume: 800)
            await refresh.value
            await drainUpdates()
            XCTAssertEqual(form.volumeSeason?.id, "active", "Never substitute a different season")
            XCTAssertEqual(form.volumeSeason?.status, status)
            XCTAssertNil(form.volumeBreakdown, "Only Active can show Automatic")
            XCTAssertNotNil(form.saleSummaryMessage)
            XCTAssertFalse(form.isSaveButtonEnabled)
            fixture.state.createTransaction[\.volumeAmount] = "800"
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.seasonVolume, "800")
            XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "0")
            XCTAssertTrue(form.isSaveButtonEnabled)
        }
    }

    func testCancellationAndDisappearanceRetainProvenanceAndAllowImmediateReturn() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        for cancel in [true, false] {
            let fixture = SaleRefreshFixture()
            let form = fixture.form
            let old = Task { await form.refreshBalance() }
            let oldCall = await fixture.balance.nextCall()
            XCTAssertTrue(form.isRefreshingBalance)
            if cancel { old.cancel() } else { form.stopBalanceRefresh() }
            await fixture.balance.fail(oldCall)
            await old.value
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "700")
            XCTAssertEqual(form.confirmedBalance?.balance.isCached, false)
            XCTAssertFalse(form.isRefreshingBalance)
            let next = Task { await form.refreshBalance() }
            let nextCall = await fixture.balance.nextCall()
            await fixture.balance.complete(nextCall, volume: 800, isCached: true)
            await next.value
            await drainUpdates()
            XCTAssertEqual(form.volumeBreakdown?.automaticVolume, "400")
            XCTAssertEqual(form.confirmedBalance?.balance.isCached, true)
            XCTAssertFalse(form.isRefreshingBalance)
        }
    }

    func testDepartedFormCannotClearOrOverwriteAReplacementDraft() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        var current: CreateTransactionFormModule.ViewModel?
        var state: FilterAppStateTestDouble?
        do {
            let fixture = SaleRefreshFixture()
            state = fixture.state
            let old = Task { await fixture.form.refreshBalance() }
            let call = await fixture.balance.nextCall()
            current = .init(transactionType: fixture.transactionType)
            fixture.state.createTransaction[\.volumeAmount] = "42"
            await fixture.balance.complete(call, volume: 10)
            await old.value
        }
        await drainUpdates()
        XCTAssertEqual(state?.createTransaction.value.volumeAmount, "42")
        XCTAssertEqual(current?.volumeBreakdown?.seasonVolume, "42")
        XCTAssertEqual(current?.confirmedBalance?.balance.volume, 500)
        withExtendedLifetime(current) {}
    }

    func testBuyerReturnNeverLoadsSupplierBalanceOrBlocksSave() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = SaleRefreshFixture(knownVolume: nil)
        let buyer = CreateTransactionFormModule.ViewModel(transactionType: .downstream(action: .buy,
            recipient: .init(recipientID: "test-supplier", email: "", phone: "")))
        await buyer.refreshBalance()
        await drainUpdates()
        let count = await fixture.balance.pendingCount
        XCTAssertEqual(count, 0)
        XCTAssertNil(buyer.volumeBreakdown)
        XCTAssertNil(buyer.saleSummaryMessage)
        XCTAssertTrue(buyer.isSaveButtonEnabled)
    }

    func testBalanceRefreshDoesNotInvalidateUnchangedSubmissionInputs() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = SaleRefreshFixture()
        let draft = fixture.state.createTransaction.value
        let refresh = Task { await fixture.form.refreshBalance() }
        let call = await fixture.balance.nextCall()
        await fixture.balance.complete(call, volume: 800)
        await refresh.value
        let refreshed = fixture.state.createTransaction.value
        XCTAssertTrue(draft.hasSameSubmissionInputs(as: refreshed), "A balance refresh during location lookup must reach final sale revalidation")
        var edited = refreshed
        edited.volumeAmount = "42"
        XCTAssertFalse(draft.hasSameSubmissionInputs(as: edited))
        edited = refreshed
        edited.farmLocation = nil
        XCTAssertFalse(draft.hasSameSubmissionInputs(as: edited))
        edited = refreshed
        edited.transactionType = .downstream(action: .sell, recipient: .empty)
        XCTAssertFalse(draft.hasSameSubmissionInputs(as: edited))
        edited = refreshed
        edited.seasonSelection = nil
        XCTAssertFalse(draft.hasSameSubmissionInputs(as: edited))
        edited = refreshed
        edited.clear()
        XCTAssertFalse(draft.hasSameSubmissionInputs(as: edited))
    }

    private func drainUpdates() async {
        let delivered = expectation(description: "Form state delivered")
        DispatchQueue.main.async { delivered.fulfill() }
        await fulfillment(of: [delivered], timeout: 2)
    }
}

@MainActor
private final class SaleRefreshFixture {
    let state = FilterAppStateTestDouble()
    let balance = FormBalanceResponses()
    let transactionType = TransactionType.downstream(action: .sell,
        recipient: .init(recipientID: "test-buyer", email: "", phone: ""))
    let evidence = FarmLocation.manual(coordinates: .init(latitude: 1, longitude: 2))
    let season = HarvestSeason(id: "active", name: "Cocoa season", startDate: .distantPast, endDate: .distantFuture, status: .active)
    let form: CreateTransactionFormModule.ViewModel

    init(knownVolume: Double? = 500) {
        let state = state
        let balance = balance
        let season = season
        let evidence = evidence
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { balance }.scope(.unique)
        state.createTransaction.dispatch {
            $0.commodityType = BuyerVolumeTests.commodity
            $0.volumeAmount = "1200"
            $0.seasonSelection = .init(commodityId: "beans", season: season)
            $0.farmLocation = evidence
            $0.confirmedBalance = knownVolume.map {
                .init(commodityId: "beans", seasonId: "active", balance: .init(volume: $0, traceability: nil, isCached: false))
            }
        }
        form = .init(transactionType: transactionType)
    }
}

private actor FormBalanceResponses: CreationSeasonInteractor {
    struct Call {
        let id: UUID
        let commodityId: String
        let seasonId: String
    }
    var pendingCount: Int { pending.count }
    private var status: HarvestSeasonStatus?
    func setStatus(_ status: HarvestSeasonStatus) { self.status = status }

    private var pending: [UUID: CheckedContinuation<ExactSeasonalBalance, Error>] = [:]
    private var calls: [Call] = []
    private var waiter: CheckedContinuation<Call, Never>?

    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        throw CreationSeasonError.catalogueRequired
    }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        let season = try XCTUnwrap(selection?.season)
        return .init(id: season.id, name: season.name, startDate: season.startDate, endDate: season.endDate, status: status ?? season.status)
    }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        let call = Call(id: UUID(), commodityId: commodityId, seasonId: seasonId)
        return try await withCheckedThrowingContinuation {
            pending[call.id] = $0
            if let waiter {
                self.waiter = nil
                waiter.resume(returning: call)
            } else {
                calls.append(call)
            }
        }
    }
    func nextCall() async -> Call {
        if !calls.isEmpty { return calls.removeFirst() }
        return await withCheckedContinuation { waiter = $0 }
    }
    func complete(_ call: Call, volume: Double, isCached: Bool = false) {
        pending.removeValue(forKey: call.id)?.resume(returning: .init(volume: volume, traceability: nil, isCached: isCached))
    }
    func fail(_ call: Call) {
        pending.removeValue(forKey: call.id)?.resume(throwing: SeasonalBalanceError.unavailableCache)
    }
}
