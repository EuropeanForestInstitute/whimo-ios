//
//  TransactionAcceptanceBalanceTests+Refresh.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 10.09.2026.
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
import Combine
import FactoryKit
import Resources
@testable import Whimo

extension TransactionAcceptanceBalanceTests {
    func testConflictRefreshesShortageAndAllowsReplenishmentRetry() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.volume = 20
        let model = try await details(fixture, balances: balances)
        await settled(model)
        fixture.target.conflict = true
        fixture.target.seasonStatus = "past"
        balances.volume = 0
        await model.didTapAcceptTransaction()
        XCTAssertEqual(model.transaction.value?.status, .pending)
        XCTAssertNil(model.statusOutcome)
        XCTAssertEqual(model.acceptanceShortage?.available, 0)
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertFalse(model.canAcceptTransaction)
        XCTAssertEqual(fixture.target.requests.count, 1)
        balances.volume = 12
        fixture.target.conflict = false
        await model.refresh()
        XCTAssertTrue(model.canAcceptTransaction)
        await model.didTapAcceptTransaction()
        XCTAssertEqual(model.transaction.value?.status, .accepted)
        XCTAssertEqual(fixture.target.requests.count, 2)
    }

    func testReturnDiscardsObsoleteSeasonResponseAndForegroundReplenishes() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.onAppear()
        let initialReads = fixture.target.fetchCount
        fixture.target.fetchRequested = expectation(description: "Old Details request suspended")
        let stale = try fixture.target.decodeTransaction(status: "pending")
        let oldRefresh = Task { await model.refresh() }
        await fulfillment(of: [try XCTUnwrap(fixture.target.fetchRequested)], timeout: 5)
        let oldResponse = try XCTUnwrap(fixture.target.fetchSuspension)
        oldRefresh.cancel()
        model.onDisappear()
        XCTAssertFalse(model.isRefreshing)
        fixture.target.fetchRequested = nil
        fixture.target.seasonStatus = "archived"
        await model.onAppear()
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .archive)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
        oldResponse.resume(returning: .init(data: stale))
        await oldRefresh.value
        await drainMainQueue()
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .archive)
        XCTAssertFalse(model.canAcceptTransaction)
        balances.volume = 12
        await model.onForeground()
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertNil(model.acceptanceShortage)
        XCTAssertEqual(fixture.target.fetchCount, initialReads + 3)
    }

    func testRefreshTransitionsFromActiveToPastThenReplenishedWithoutChangingScope() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, 7)
        let balanceQuery = fixture.state.balance.value.query
        let transactionQuery = fixture.state.transactions.value.query
        fixture.target.seasonStatus = "past"
        await model.refreshAcceptanceBalance()
        XCTAssertNil(model.acceptanceAutomaticPreview)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertFalse(model.canAcceptTransaction)
        balances.volume = 12
        await model.refreshAcceptanceBalance()
        XCTAssertNil(model.acceptanceShortage)
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(model.transaction.value?.harvestSeasonId, "stored-season")
        XCTAssertTrue(balances.exactQueries.allSatisfy { $0 == "beans" && $1 == "stored-season" })
        XCTAssertEqual(fixture.state.balance.value.query, balanceQuery)
        XCTAssertEqual(fixture.state.transactions.value.query, transactionQuery)
    }

    func testInitialTriggersCoalesceAndReturningIgnoresCancelledBalance() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.savedVolume = 20
        balances.suspend = true
        balances.requested = expectation(description: "Initial balance suspended")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        let oldBalance = try XCTUnwrap(balances.suspension)
        let appearance = Task { await model.onAppear() }
        await drainMainQueue()
        await model.refresh()
        await model.onForeground()
        XCTAssertEqual(balances.exactQueries.count, 1)
        XCTAssertEqual(fixture.target.fetchCount, 1)
        XCTAssertTrue(model.canAcceptTransaction)
        model.onDisappear()
        XCTAssertFalse(model.isRefreshing)
        balances.suspend = false
        balances.requested = nil
        balances.volume = 12
        await model.onAppear()
        oldBalance.resume(returning: .init(volume: 0, traceability: nil, isCached: false))
        await appearance.value
        XCTAssertEqual(model.acceptanceBalance?.volume, 12)
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertFalse(model.isRefreshing)
        XCTAssertFalse(model.isLoadingAcceptanceBalance)
        let reads = fixture.target.fetchCount
        model.onDisappear()
        await model.onForeground()
        XCTAssertEqual(fixture.target.fetchCount, reads, "Hidden Details must not refresh")
    }

    func testFailureAndRecoveryRetainKnownZeroNonzeroAndUnknownDistinctly() async throws {
        for status in ["active", "past", "archived"] {
            for initial in [nil, 0.0, 5.0] as [Double?] {
                let fixture = try AcceptanceFixture(seasonStatus: status)
                defer { fixture.storage.storage.clear() }
                let balances = AcceptanceBalanceRepository()
                balances.volume = initial ?? 0
                if initial == nil { balances.error = SeasonalBalanceError.incompleteResponse }
                let model = try await details(fixture, balances: balances)
                await settled(model)
                for error in [URLError(.notConnectedToInternet), URLError(.badServerResponse)] {
                    balances.error = error
                    fixture.target.fetchError = error
                    await model.refresh()
                    XCTAssertEqual(model.acceptanceBalance?.volume, initial)
                    XCTAssertEqual(model.isAcceptanceBalanceUnavailable, initial == nil)
                    XCTAssertEqual(model.transaction.value?.harvestSeason?.status.rawValue, status)
                    XCTAssertTrue(model.hasDetailsRefreshError)
                    XCTAssertEqual(model.canAcceptTransaction, initial != nil && status == "active")
                }
                balances.error = nil
                fixture.target.fetchError = nil
                balances.volume = 12
                await model.refresh()
                XCTAssertFalse(model.hasDetailsRefreshError)
                XCTAssertFalse(model.hasAcceptanceBalanceError)
                XCTAssertTrue(model.canAcceptTransaction)
                XCTAssertNil(model.acceptanceShortage)
                XCTAssertNil(model.acceptanceAutomaticPreview)
            }
        }
    }

    func testLatestBackendSeasonSurvivesMissingMetadataAndFailure() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        fixture.target.seasonStatus = "past"
        await model.refresh()
        fixture.target.fetchError = URLError(.badServerResponse)
        balances.error = SeasonalBalanceError.incompleteResponse
        await model.refresh()
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
        fixture.target.fetchError = nil
        fixture.target.missingSeason = true
        await model.refresh()
        XCTAssertEqual(model.transaction.value?.harvestSeasonId, "stored-season")
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
        XCTAssertFalse(model.canAcceptTransaction)
    }

    func testConfirmedStatusSurvivesObsoleteReadAndSubsequentRefreshFailure() async throws {
        for accepted in [true, false] {
            let fixture = try AcceptanceFixture(seasonStatus: "active", automatic: accepted)
            defer { fixture.storage.storage.clear() }
            let balances = AcceptanceBalanceRepository()
            let model = try await details(fixture, balances: balances)
            await settled(model)
            await model.onAppear()
            fixture.target.fetchRequested = expectation(description: "Pending read before status submission")
            let pending = try fixture.target.decodeTransaction(status: "pending")
            let oldRefresh = Task { await model.refresh() }
            await fulfillment(of: [try XCTUnwrap(fixture.target.fetchRequested)], timeout: 5)
            let oldResponse = try XCTUnwrap(fixture.target.fetchSuspension)
            fixture.target.fetchRequested = nil
            if accepted { await model.didTapAcceptTransaction() } else { await model.didTapRejectTransaction() }
            let expected: TransactionModel.Status = accepted ? .accepted : .rejected
            XCTAssertEqual(model.transaction.value?.status, expected)
            XCTAssertFalse(model.isRefreshing)
            oldResponse.resume(returning: .init(data: pending))
            await oldRefresh.value
            await drainMainQueue()
            fixture.target.fetchError = URLError(.notConnectedToInternet)
            await model.onForeground()
            XCTAssertEqual(model.transaction.value?.status, expected)
            XCTAssertEqual(model.statusOutcome?.automaticTransaction?.volume, accepted ? 7 : nil)
            XCTAssertTrue(model.hasStatusRefreshError)
            XCTAssertFalse(model.isSubmittingStatus)
            XCTAssertNil(model.acceptanceAutomaticPreview)
            let stored = try await fixture.local.fetchTransaction(by: "ordinary")
            XCTAssertEqual(stored.status, expected, "The obsolete read cannot overwrite the confirmed SQLite result")
            XCTAssertEqual(fixture.target.requests.count, 1)
        }
    }

    func testCancelledRefreshRecoversWithoutDisappearanceOrFalseError() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        balances.suspend = true
        balances.requested = expectation(description: "Cancelled exact read")
        let task = Task { await model.refresh() }
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        task.cancel()
        balances.suspension?.resume(throwing: CancellationError())
        await task.value
        XCTAssertFalse(model.isRefreshing)
        XCTAssertFalse(model.isLoadingAcceptanceBalance)
        XCTAssertFalse(model.hasAcceptanceBalanceError)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
        balances.suspend = false
        balances.requested = nil
        balances.volume = 12
        await model.refresh()
        XCTAssertTrue(model.canAcceptTransaction)
    }

    func testIndependentListReloadsDoNotEraseDetailsOrChangeItsExactScope() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        fixture.state.balance.dispatch { $0.query = .init(search: "coffee", filter: .init(group: .init(id: "coffee", name: "Coffee"))) }
        fixture.state.transactions.dispatch { $0.query = .init(search: "Cocoa", action: .sell, filter: .init(group: .init(id: "cocoa", name: "Cocoa"))) }
        let balanceQuery = fixture.state.balance.value.query
        let transactionQuery = fixture.state.transactions.value.query
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.onAppear()
        fixture.state.transactions.dispatch { $0.list = .notRequested }
        await drainMainQueue()
        XCTAssertEqual(model.transaction.value?.id, "ordinary")
        fixture.state.transactions.dispatch { $0.list = .requested(lastValue: nil) }
        await drainMainQueue()
        XCTAssertEqual(model.transaction.value?.id, "ordinary")
        model.onDisappear()
        await model.onAppear()
        await model.onForeground()
        await model.refresh()
        XCTAssertEqual(fixture.state.balance.value.query, balanceQuery)
        XCTAssertEqual(fixture.state.transactions.value.query, transactionQuery)
        XCTAssertTrue(balances.exactQueries.allSatisfy { $0 == "beans" && $1 == "stored-season" })
        XCTAssertTrue(balances.queries.isEmpty)
    }
    func testStaleListCannotRestoreActiveAfterSeasonRefreshOrConfirmedServerStatus() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        fixture.target.seasonStatus = "past"
        await model.refresh()
        fixture.state.transactions.dispatch { $0.hasListError = true }
        await drainMainQueue()
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertFalse(model.canAcceptTransaction)
        fixture.target.fetchStatus = "accepted"
        await model.refresh()
        XCTAssertEqual(model.transaction.value?.status, .accepted)
        fixture.state.transactions.dispatch { $0.hasListError = false }
        await drainMainQueue()
        XCTAssertEqual(model.transaction.value?.status, .accepted)
    }

    func testOfflineReopeningRetainsRefreshedSeasonFromRealSQLite() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        fixture.target.seasonStatus = "past"
        await model.refresh()
        model.onDisappear()
        fixture.target.fetchError = URLError(.notConnectedToInternet)
        balances.isCached = true
        let reopened = try await details(fixture, balances: balances, savePending: false)
        await settled(reopened)
        XCTAssertEqual(reopened.transaction.value?.harvestSeason?.status, .past)
        XCTAssertEqual(reopened.acceptanceShortage?.available, 5)
        XCTAssertFalse(reopened.canAcceptTransaction)
    }

    func testRecoveredSeasonIdentityLoadsBalanceDuringSameRefresh() async throws {
        var fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        fixture.pending.harvestSeasonId = nil
        fixture.pending.harvestSeason = nil
        fixture.target.fetchRequested = expectation(description: "Recovering missing identity")
        let balances = AcceptanceBalanceRepository()
        balances.volume = 12
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(fixture.target.fetchRequested)], timeout: 5)
        let unavailable = expectation(description: "No exact identity yet")
        let observation = model.$hasAcceptanceBalanceError.filter { $0 }.first().sink { _ in unavailable.fulfill() }
        await fulfillment(of: [unavailable], timeout: 5)
        observation.cancel()
        fixture.target.fetchSuspension?.resume(returning: .init(data: try fixture.target.decodeTransaction(status: "pending")))
        await settled(model)
        XCTAssertEqual(balances.exactQueries.count, 1)
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(model.transaction.value?.harvestSeasonId, "stored-season")
    }

    func testCancelledCacheReadCannotStartAnotherRemoteBalanceRequest() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.savedRequested = expectation(description: "Cached value suspended")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.savedRequested)], timeout: 5)
        let oldCache = try XCTUnwrap(balances.savedSuspension)
        let appearance = Task { await model.onAppear() }
        await drainMainQueue()
        model.onDisappear()
        balances.savedRequested = nil
        balances.volume = 12
        await model.onAppear()
        oldCache.resume(throwing: CancellationError())
        await appearance.value
        XCTAssertEqual(balances.exactQueries.count, 1)
        XCTAssertEqual(model.acceptanceBalance?.volume, 12)
    }

    func testPullRefreshSurvivesCallerCancellationWhileResponseIsPending() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.onAppear()
        fixture.target.seasonStatus = "archived"
        balances.volume = 12
        fixture.target.fetchRequested = expectation(description: "Pull response suspended")
        let caller = Task { await model.didPullRefresh() }
        await fulfillment(of: [try XCTUnwrap(fixture.target.fetchRequested)], timeout: 5)
        let response = try XCTUnwrap(fixture.target.fetchSuspension)
        caller.cancel()
        response.resume(returning: .init(data: try fixture.target.decodeTransaction(status: "pending")))
        await caller.value
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .archive)
        XCTAssertEqual(model.acceptanceBalance?.volume, 12)
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertFalse(model.isRefreshing)
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

    func testPullRefreshStartsFromCancelledVisibleCaller() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.onAppear()
        let reads = fixture.target.fetchCount
        balances.volume = 12
        await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await model.didPullRefresh()
        }.value
        XCTAssertEqual(fixture.target.fetchCount, reads + 1)
        XCTAssertEqual(model.acceptanceBalance?.volume, 12)
        XCTAssertTrue(model.canAcceptTransaction)
    }

    func testPullRefreshCoalescesAndDisappearanceInvalidatesItsResponse() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.onAppear()
        let initialReads = fixture.target.fetchCount
        let obsolete = try fixture.target.decodeTransaction(status: "pending")
        fixture.target.fetchRequested = expectation(description: "Owned pull suspended")
        let first = Task { await model.didPullRefresh() }
        await fulfillment(of: [try XCTUnwrap(fixture.target.fetchRequested)], timeout: 5)
        let response = try XCTUnwrap(fixture.target.fetchSuspension)
        let second = Task { await model.didPullRefresh() }
        await drainMainQueue()
        XCTAssertEqual(fixture.target.fetchCount, initialReads + 1)
        model.onDisappear()
        await model.didPullRefresh()
        XCTAssertEqual(fixture.target.fetchCount, initialReads + 1, "Late hidden gesture cannot start work")
        fixture.target.fetchRequested = nil
        fixture.target.seasonStatus = "past"
        await model.onAppear()
        response.resume(returning: .init(data: obsolete))
        await first.value
        await second.value
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)
        XCTAssertFalse(model.canAcceptTransaction)
        balances.volume = 12
        await model.didPullRefresh()
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(fixture.target.fetchCount, initialReads + 3)
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

}
