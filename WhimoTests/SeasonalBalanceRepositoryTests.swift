//
//  SeasonalBalanceRepositoryTests.swift
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
import DatabaseKit
import GRDB
import RestClient
import Targets
@testable import Whimo

final class SeasonalBalanceRepositoryTests: XCTestCase {
    func testPartialBalanceListRowSatisfiesOfflineExactLookupAfterDatabaseReopening() async throws {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        defer { try? FileManager.default.removeItem(atPath: path) }
        let target = BalanceTargetDouble()
        await target.paginate()
        let mapper = SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper())
        let database = try DatabaseImpl(writer: DatabaseQueue(path: path))
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "fixture" })
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        await target.goOffline()
        let reopened: SeasonalBalanceRepository = SeasonalBalanceRepositoryImpl(target: target,
            database: try DatabaseImpl(writer: DatabaseQueue(path: path)), mapper: mapper, accountId: { "fixture" })
        let balance = try await reopened.exact(commodityId: "bean", seasonId: "active")
        XCTAssertEqual(balance.volume, 25)
        XCTAssertEqual(balance.traceability, .partialTraceability)
        XCTAssertTrue(balance.isCached)
        let cached = try await reopened.cachedExact(commodityId: "bean", seasonId: "active")
        XCTAssertEqual(cached, balance)
    }

    func testBothSaveOrdersAndLaterZeroSurviveReopeningWithoutPromotingCacheReads() async throws {
        for listLast in [true, false] {
            let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
            defer { try? FileManager.default.removeItem(atPath: path) }
            let target = BalanceTargetDouble()
            let database = try DatabaseImpl(writer: DatabaseQueue(path: path))
            let repository = makeRepository(database: database, target: target)
            for list in [!listLast, listLast] {
                try await target.returnBalance(volume: list ? 7 : 10)
                if list {
                    _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
                } else {
                    _ = try await repository.exact(commodityId: "bean", seasonId: "past")
                }
            }
            _ = try await repository.page(query: .init(), page: 1, cacheOnly: true)
            _ = try await repository.page(query: .init(commodityId: "bean", exactSeasonId: "past"), page: 1, cacheOnly: true)
            await target.goOffline()
            let reopened = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue(path: path)), target: target)
            let balance = try await reopened.exact(commodityId: "bean", seasonId: "past")
            XCTAssertEqual(balance.volume, listLast ? 7 : 10)
            XCTAssertTrue(balance.isCached)
            try await target.returnBalance(volume: nil)
            _ = try await reopened.exact(commodityId: "bean", seasonId: "past")
            await target.goOffline()
            let zero = try await makeRepository(database: try DatabaseImpl(writer: DatabaseQueue(path: path)), target: target)
                .exact(commodityId: "bean", seasonId: "past")
            XCTAssertEqual(zero.volume, 0)
            XCTAssertTrue(zero.isCached)
        }
    }

    func testCancelledSaveCannotCommitAfterWaitingForPersistence() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        try await target.returnBalance(volume: 10)
        let entered = expectation(description: "Balance write waiting")
        let gate = PreloadWriteGate(entered: entered)
        let repository = makeRepository(database: PreloadPausedDatabase(database: database, gate: gate), target: target)
        let pending = Task { try await repository.page(query: .init(), page: 1, cacheOnly: false) }
        await fulfillment(of: [entered], timeout: 3)
        pending.cancel()
        await gate.release()
        do { _ = try await pending.value; XCTFail("Cancelled persistence must fail") } catch is CancellationError { }
        let reader = makeRepository(database: database, target: target)
        do {
            _ = try await reader.cachedExact(commodityId: "bean", seasonId: "past")
            XCTFail("Cancellation must not establish a saved balance")
        } catch SeasonalBalanceError.unavailableCache { }
    }

    func testFailedPersistenceAndServerRefreshRetainLatestSavedListValue() async throws {
        let writer = try DatabaseQueue()
        let database = try DatabaseImpl(writer: writer)
        let target = BalanceTargetDouble()
        let repository = makeRepository(database: database, target: target)
        try await target.returnBalance(volume: 7)
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        try await writer.write { db in
            try db.execute(sql: """
                CREATE TRIGGER reject_balance BEFORE UPDATE ON seasonalBalanceCache
                BEGIN SELECT RAISE(ABORT, 'fixture persistence failure'); END
                """)
        }
        try await target.returnBalance(volume: nil)
        let retained = try await repository.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(retained.volume, 7)
        XCTAssertTrue(retained.isCached)
        await target.fail()
        let failed = try await repository.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(failed.volume, 7)
        let reopened = try await makeRepository(database: database, target: target).cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(reopened.volume, 7)
    }

    func testFilteredAndPartialListsDoNotProveAbsentPairsAndConflictsDoNotReplaceValidRows() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        let repository = makeRepository(database: database, target: target)
        try await target.returnBalance(volume: 7, partial: true)
        _ = try await repository.page(query: .init(search: "beans", filter: .init(group: .init(id: "coffee", name: "Coffee"))),
                                      page: 1, cacheOnly: false)
        for (commodity, season) in [("other", "past"), ("bean", "other")] {
            do {
                _ = try await repository.cachedExact(commodityId: commodity, seasonId: season)
                XCTFail("Unrelated pairs stay unknown")
            } catch SeasonalBalanceError.unavailableCache { }
        }
        let other = makeRepository(database: database, target: target, accountId: { "other" })
        do {
            _ = try await other.cachedExact(commodityId: "bean", seasonId: "past")
            XCTFail("Another account cannot reuse a row")
        } catch SeasonalBalanceError.unavailableCache { }
        try await target.returnBalance(volume: nil)
        _ = try await repository.page(query: .init(search: "absent"), page: 1, cacheOnly: false)
        let retained = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(retained.volume, 7)
        try await target.returnBalance(volume: 100, duplicate: true)
        do {
            _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
            XCTFail("Conflicting rows must not manufacture a new balance")
        } catch SeasonalBalanceError.incompleteResponse { }
        let final = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(final.volume, 7)
    }

    func testConcurrentRepositoriesUseSaveCompletionOrderAndFailureReadsNewestObservation() async throws {
        let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
        defer { try? FileManager.default.removeItem(atPath: path) }
        let target = BalanceTargetDouble()
        let otherTarget = BalanceTargetDouble()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: path))
        let first = makeRepository(database: database, target: target)
        let second = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue(path: path)), target: otherTarget)
        try await target.returnBalance(volume: 10)
        let entered = expectation(description: "Earlier exact request paused")
        await target.pauseNext(entered: entered)
        let pending = Task { try await first.exact(commodityId: "bean", seasonId: "past") }
        await fulfillment(of: [entered], timeout: 3)
        try await otherTarget.returnBalance(volume: 7)
        _ = try await second.page(query: .init(), page: 1, cacheOnly: false)
        await target.resume()
        _ = try await pending.value
        let saved = try await second.cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(saved.volume, 10, "Save completion, not request start, determines the latest value")

        await target.fail()
        let failureEntered = expectation(description: "Failing refresh paused")
        await target.pauseNext(entered: failureEntered)
        let failure = Task { try await first.exact(commodityId: "bean", seasonId: "past") }
        await fulfillment(of: [failureEntered], timeout: 3)
        _ = try await second.page(query: .init(), page: 1, cacheOnly: false)
        await target.resume()
        let fallback = try await failure.value
        XCTAssertEqual(fallback.volume, 7)
        XCTAssertTrue(fallback.isCached)
    }

    func testMalformedCompleteZeroCannotReplaceSavedBalance() async throws {
        let target = BalanceTargetDouble()
        let repository = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue()), target: target)
        try await target.returnBalance(volume: 7)
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        try await target.returnJSON("""
            {"success":true,"data":[],"pagination":{"page":1,"page_size":20,"count":0,
            "total_pages":1,"next_page":null,"previous_page":1}}
            """)
        let balance = try await repository.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(balance.volume, 7, "An inconsistent first-page predecessor cannot prove a complete zero")
        XCTAssertTrue(balance.isCached)
    }

    func testLegacySnapshotsRequireAgreementUntilAnOrderedSaveSucceeds() async throws {
        struct LegacySnapshot: Encodable { let pages: [Int: SeasonalBalancePage] }
        for conflicting in [true, false] {
            let path = NSTemporaryDirectory() + UUID().uuidString + ".sqlite"
            defer { try? FileManager.default.removeItem(atPath: path) }
            let database = try DatabaseImpl(writer: DatabaseQueue(path: path))
            let target = BalanceTargetDouble()
            let mapper = SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper())
            for exact in [true, false] {
                try await target.returnBalance(volume: exact && conflicting ? 10 : 7)
                let response = try await target.balances(.init())
                let page = try mapper.toDomain(response, requestedPage: 1)
                let fields: [String?] = ["fixture", "", nil, nil, exact ? "bean" : nil, exact ? "past" : nil]
                let key = try JSONEncoder().encode(fields).base64EncodedString()
                try await database.save(SeasonalBalanceCache(id: key, payload: JSONEncoder().encode(LegacySnapshot(pages: [1: page]))))
            }
            await target.goOffline()
            let repository = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue(path: path)), target: target)
            do {
                let balance = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
                XCTAssertFalse(conflicting)
                XCTAssertEqual(balance.volume, 7)
                XCTAssertTrue(balance.isCached)
            } catch SeasonalBalanceError.unavailableCache { XCTAssertTrue(conflicting) }
            try await target.returnBalance(volume: 5)
            _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
            let ordered = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
            XCTAssertEqual(ordered.volume, 5)
        }
    }

    func testAccountSwitchAtPersistenceBoundaryCannotRestoreClearedBalances() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BalanceTargetDouble()
        try await target.returnBalance(volume: 10)
        let entered = expectation(description: "Old account write waiting")
        let gate = PreloadWriteGate(entered: entered)
        let account: () -> String? = { (fixture.storage.get(.user) as UserModel?)?.id }
        let repository = makeRepository(database: PreloadPausedDatabase(database: fixture.database, gate: gate), target: target, accountId: account)
        let pending = Task { try await repository.page(query: .init(), page: 1, cacheOnly: false) }
        await fulfillment(of: [entered], timeout: 3)
        fixture.storage.set(UserModel(id: "new-account", username: "Fixture", gadgets: []), key: .user)
        try await fixture.database.flush()
        await gate.release()
        do { _ = try await pending.value; XCTFail("Obsolete account work must fail") } catch is CancellationError { }
        for participant in ["fixture-buyer", "new-account"] {
            let reader = makeRepository(database: fixture.database, target: target, accountId: { participant })
            do {
                _ = try await reader.cachedExact(commodityId: "bean", seasonId: "past")
                XCTFail("The delayed write must not repopulate either account")
            } catch SeasonalBalanceError.unavailableCache { }
        }
    }

    func testObsoleteSameQueryResponseCannotOverwriteNewerRefresh() async throws {
        let target = BalanceTargetDouble()
        let repository = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue()), target: target)
        try await target.returnBalance(volume: 10)
        let entered = expectation(description: "Old query paused")
        await target.pauseNext(entered: entered)
        let pending = Task { try await repository.page(query: .init(), page: 1, cacheOnly: false) }
        await fulfillment(of: [entered], timeout: 3)
        try await target.returnBalance(volume: 7)
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        await target.resume()
        do { _ = try await pending.value; XCTFail("Obsolete query must fail") } catch is CancellationError { }
        let saved = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(saved.volume, 7)
    }

    func testObsoleteWriteCannotOverwriteRefreshThatSavedWhileItWaited() async throws {
        for exact in [true, false] {
            let database = try DatabaseImpl(writer: DatabaseQueue())
            let target = BalanceTargetDouble()
            try await target.returnBalance(volume: 10)
            let entered = expectation(description: "Old write paused")
            let gate = PreloadWriteGate(entered: entered, onlyFirst: true)
            let repository = makeRepository(database: PreloadPausedDatabase(database: database, gate: gate), target: target)
            let pending = Task {
                if exact {
                    _ = try await repository.exact(commodityId: "bean", seasonId: "past")
                } else {
                    _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
                }
            }
            await fulfillment(of: [entered], timeout: 3)
            try await target.returnBalance(volume: 7)
            if exact {
                _ = try await repository.exact(commodityId: "bean", seasonId: "past")
            } else {
                _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
            }
            await gate.release()
            do { try await pending.value; XCTFail("Obsolete work must propagate cancellation") } catch is CancellationError { }
            let saved = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
            XCTAssertEqual(saved.volume, 7)
        }
    }

    func testDuplicatePairAcrossListPagesDoesNotBecomeANewerObservation() async throws {
        let target = BalanceTargetDouble()
        let repository = makeRepository(database: try DatabaseImpl(writer: DatabaseQueue()), target: target)
        try await target.returnBalance(volume: 7, partial: true)
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        try await target.returnBalance(volume: 100, partial: true, pageNumber: 2)
        do {
            _ = try await repository.page(query: .init(), page: 2, cacheOnly: false)
            XCTFail("A duplicate pair in one list snapshot is conflicting evidence")
        } catch { }
        let balance = try await repository.cachedExact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(balance.volume, 7)
    }

    private func makeRepository(database: DatabaseKit.Database, target: BalanceTargetDouble,
                                accountId: @escaping () -> String? = { "fixture" }) -> SeasonalBalanceRepositoryImpl {
        SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: accountId)
    }

    func testFreshServerFailureRetainsValidatedExactCache() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        await target.returnEmpty(count: 0)
        _ = try await repository.exact(commodityId: "bean", seasonId: "past")
        await target.fail()
        let reopened = SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        let saved = try await reopened.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(saved.volume, 0)
        XCTAssertTrue(saved.isCached)
    }

    func testInvalidRefreshDoesNotDestroyUsableCacheAndOtherAccountsCannotReadIt() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        let mapper = SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper())
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "seller" })
        await target.returnEmpty(count: 0)
        _ = try await repository.exact(commodityId: "bean", seasonId: "past")
        await target.returnWrongPair()
        let retained = try await repository.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(retained.volume, 0)
        await target.fail()
        let reopened = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "seller" })
        let saved = try await reopened.exact(commodityId: "bean", seasonId: "past")
        XCTAssertEqual(saved.volume, 0)
        let other = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "other" })
        do {
            _ = try await other.cachedExact(commodityId: "bean", seasonId: "past")
            XCTFail("A different participant cannot reuse the snapshot")
        } catch SeasonalBalanceError.unavailableCache { }
    }

    func testReturnedTraceabilityLevelsAndNullSurviveSeasonalCacheRestoration() async throws {
        let cases: [(values: [String?], expected: [TransactionModel.Traceability?])] = [
            (["full", "conditional"], [.fullTraceability, .conditionalTraceability]),
            (["partial", "incomplete"], [.partialTraceability, .incompleteTraceability]),
            ([nil, nil], [nil, nil])
        ]
        for fixture in cases {
            let database = try DatabaseImpl(writer: DatabaseQueue())
            let target = BalanceTargetDouble()
            await target.returnTraceabilities(fixture.values)
            let mapper = SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper())
            let repository = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "fixture" })

            let fetched = try await repository.page(query: .init(), page: 1, cacheOnly: false)
            XCTAssertFalse(fetched.isCached)
            XCTAssertEqual(fetched.rows.map(\.traceability), fixture.expected)
            XCTAssertEqual(fetched.rows.map(\.volume), [25, 7])
            XCTAssertEqual(fetched.rows.map { $0.commodity.id }, ["bean", "bean"])
            XCTAssertEqual(fetched.rows.map { $0.season?.id }, ["active", "past"])
            XCTAssertEqual(fetched.rows.map { $0.season?.name }, ["Coffee 2026/27", "Coffee 2025/26"])
            XCTAssertEqual(fetched.rows.map { $0.season?.status }, [.active, .past])

            await target.goOffline()
            let restored = SeasonalBalanceRepositoryImpl(target: target, database: database, mapper: mapper, accountId: { "fixture" })
            let cached = try await restored.page(query: .init(), page: 1, cacheOnly: false)
            XCTAssertTrue(cached.isCached)
            XCTAssertEqual(cached.rows.map(\.traceability), fixture.expected)
            XCTAssertEqual(cached.rows, fetched.rows)
        }
    }

    func testExactZeroRequiresCompleteResponseAndKeepsCachedProvenance() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        await target.returnEmpty(count: 0)
        let zero = try await repository.exact(commodityId: "bean", seasonId: "empty")
        XCTAssertEqual(zero.volume, 0)
        XCTAssertNil(zero.traceability)
        XCTAssertFalse(zero.isCached)
        await target.goOffline()
        let cached = try await repository.exact(commodityId: "bean", seasonId: "empty")
        XCTAssertEqual(cached.volume, 0)
        XCTAssertTrue(cached.isCached)
        do {
            _ = try await repository.exact(commodityId: "bean", seasonId: "not-cached")
            XCTFail("Missing seasonal cache is not a proven zero")
        } catch SeasonalBalanceError.unavailableCache { }
    }

    func testIncompleteAndFailedQueriesNeverEstablishZero() async throws {
        let target = BalanceTargetDouble()
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: try DatabaseImpl(writer: DatabaseQueue()),
                                                       mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        await target.returnEmpty(count: 1)
        do {
            _ = try await repository.exact(commodityId: "bean", seasonId: "past")
            XCTFail("A response claiming an unreturned row is incomplete")
        } catch SeasonalBalanceError.incompleteResponse { }
        await target.fail()
        do {
            _ = try await repository.exact(commodityId: "bean", seasonId: "past")
            XCTFail("A failed remote query cannot establish zero")
        } catch let error as URLError { XCTAssertEqual(error.code, .badServerResponse) }
    }

    func testRefreshingPageOneInvalidatesCachedLaterPages() async throws {
        let target = BalanceTargetDouble()
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: try DatabaseImpl(writer: DatabaseQueue()),
                                                       mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        await target.paginate()
        let first = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        XCTAssertEqual(first.pagination.nextPage, 2)
        let second = try await repository.page(query: .init(), page: 2, cacheOnly: false)
        XCTAssertEqual(second.rows.first?.volume, 7)
        let cached = try await repository.page(query: .init(), page: 2, cacheOnly: true)
        XCTAssertEqual(cached.rows, second.rows)
        _ = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        do {
            _ = try await repository.page(query: .init(), page: 2, cacheOnly: true)
            XCTFail("A new first page must not be combined with the preceding snapshot's later pages")
        } catch SeasonalBalanceError.unavailableCache { }
    }

    func testSameCommodityAcrossSeasonsRetainsRowsAndMetadataInIsolatedCache() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = BalanceTargetDouble()
        let repository = SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        let first = try await repository.page(query: .init(), page: 1, cacheOnly: false)
        XCTAssertEqual(first.rows.map(\.id), ["balance-active", "balance-past"])
        XCTAssertEqual(first.rows.map(\.volume), [25, 7])
        XCTAssertEqual(first.rows.map { $0.commodity.id }, ["bean", "bean"])
        XCTAssertEqual(first.rows.map { $0.season?.id }, ["active", "past"])
        XCTAssertEqual(first.rows.first?.traceability, .partialTraceability)
        XCTAssertNil(first.rows.last?.traceability)
        XCTAssertEqual(first.pagination.count, 2)
        XCTAssertEqual(first.message, "Balances")
        await target.goOffline()
        let restored = SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture" })
        let cached = try await restored.page(query: .init(), page: 1, cacheOnly: false)
        XCTAssertTrue(cached.isCached)
        XCTAssertEqual(cached.rows, first.rows)
        XCTAssertEqual(cached.pagination, first.pagination)
        do {
            _ = try await restored.page(query: .init(search: "different"), page: 1, cacheOnly: true)
            XCTFail("A different query must not borrow cached rows or claim an empty result")
        } catch SeasonalBalanceError.unavailableCache { }
    }
}

actor BalanceTargetDouble: BalancesTarget {
    private var offline = false
    private var emptyCount: Int?
    private var failed = false
    private var paginated = false
    private var traceabilities: [String?]?
    func returnTraceabilities(_ values: [String?]) { traceabilities = values }
    func returnEmpty(count: Int) { emptyCount = count }
    func fail() { failed = true }
    func returnWrongPair() { emptyCount = nil }
    func paginate() { paginated = true }
    func goOffline() { offline = true }

    private var entered: XCTestExpectation?
    private var continuation: CheckedContinuation<Void, Never>?
    func pauseNext(entered: XCTestExpectation) { self.entered = entered }
    func resume() { continuation?.resume(); continuation = nil }
    private func pauseIfNeeded() async {
        guard let entered else { return }

        self.entered = nil
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            entered.fulfill()
        }
    }

    private var customResponse: ResponseModels.BalancesInfo?

    func returnBalance(volume: Double?, commodityId: String = "bean", seasonId: String = "past", status: String = "past",
                       duplicate: Bool = false, partial: Bool = false, pageNumber: Int = 1) throws {
        let row = """
        {"id":"row-\(pageNumber)","volume":\(volume ?? 0),"commodity":{"id":"\(commodityId)","code":"0901","name":"Beans","unit":"kg",
        "group":{"id":"coffee","name":"Coffee"}},"harvest_season":{"id":"\(seasonId)","name":"Season",
        "start_date":"2025-09-01","end_date":"2026-09-01","status":"\(status)"}}
        """
        let rows = volume == nil ? "" : duplicate ? row + "," + row.replacingOccurrences(of: "\"row-\(pageNumber)\"", with: "\"duplicate\"") : row
        let json = """
        {"success":true,"data":[\(rows)],"pagination":{"page":\(pageNumber),"page_size":20,"count":\(partial ? 21 : volume == nil ? 0 : duplicate ? 2 : 1),
        "total_pages":\(partial ? 2 : 1),"next_page":\(partial && pageNumber == 1 ? "2" : "null"),"previous_page":\(pageNumber == 1 ? "null" : "1")}}
        """
        try returnJSON(json)
    }

    func returnJSON(_ json: String) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        customResponse = try decoder.decode(ResponseModels.BalancesInfo.self, from: Data(json.utf8))
        offline = false
        failed = false
    }

    func balances(_ request: RequestModels.BalancesList) async throws -> ResponseModels.BalancesInfo {
        let offline = offline
        let failed = failed
        let customResponse = customResponse
        await pauseIfNeeded()
        if offline { throw RestClient.RestError.connectionLost }
        if failed { throw URLError(.badServerResponse) }
        if let customResponse { return customResponse }
        let json = """
        {"success":true,"message":"Balances","data":[
          {"id":"balance-active","volume":25,"commodity":{"id":"bean","code":"0901","name":"Ripe cherry","unit":"kg",
          "group":{"id":"coffee","name":"Coffee"},"has_recipe":true},"traceability":"partial",
          "harvest_season":{"id":"active","name":"Coffee 2026/27","start_date":"2026-09-01","end_date":"2027-09-01","status":"active"}},
          {"id":"balance-past","volume":7,"commodity":{"id":"bean","code":"0901","name":"Ripe cherry","unit":"kg",
          "group":{"id":"coffee","name":"Coffee"}},
          "harvest_season":{"id":"past","name":"Coffee 2025/26","start_date":"2025-09-01","end_date":"2026-09-01","status":"past"}}
        ],"pagination":{"page":1,"page_size":20,"count":2,"total_pages":1,"next_page":null,"previous_page":null}}
        """
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        if let traceabilities {
            var rows = try XCTUnwrap(object["data"] as? [[String: Any]])
            for index in rows.indices {
                rows[index]["traceability"] = traceabilities[index] as Any? ?? NSNull()
            }
            object["data"] = rows
        }
        if let emptyCount {
            object["data"] = []
            object["pagination"] = ["page": 1, "page_size": 20, "count": emptyCount, "total_pages": emptyCount == 0 ? 0 : 1,
                                    "next_page": NSNull(), "previous_page": NSNull()]
        } else if paginated {
            let rows = try XCTUnwrap(object["data"] as? [[String: Any]])
            object["data"] = [rows[request.page - 1]]
            object["pagination"] = ["page": request.page, "page_size": 1, "count": 2, "total_pages": 2,
                                    "next_page": request.page == 1 ? 2 : NSNull(), "previous_page": request.page == 2 ? 1 : NSNull()]
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.BalancesInfo.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
