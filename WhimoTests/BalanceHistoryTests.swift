//
//  BalanceHistoryTests.swift
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
import Combine
import FactoryKit
import Networking
import Utility
@testable import Whimo

@MainActor
final class BalanceHistoryTests: XCTestCase {
    func testHeadingOpensIndependentCompleteHistoryAndRowsReturnThroughBothDestinations() async {
        let repository = HistoryListDouble()
        repository.rows = (1...5).map { historyTransaction("row-\($0)", created: "2026-01-0\($0)T12:00:00.000Z") }
        await withHistory(repository) { preview, state in
            await preview.loadHistory()
            let originalPath = state.navigation.value.path
            preview.openSourceTransactions()
            XCTAssertEqual(state.navigation.value.path.last?.screen, .sourceTransactions(commodityId: "bean", seasonId: "past"))
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await list.loadNextPage()
            XCTAssertEqual(list.rows?.map(\.id), ["row-5", "row-4", "row-3", "row-2", "row-1"])
            XCTAssertEqual(preview.history?.count, 3)
            XCTAssertNil(list.nextPage)
            list.openTransaction(repository.rows[0])
            XCTAssertEqual(state.navigation.value.path.last?.screen, .transactionDetails(transactionId: "row-1"))
            state.navigation[\.path].removeLast()
            XCTAssertEqual(state.navigation.value.path.last?.screen, .sourceTransactions(commodityId: "bean", seasonId: "past"))
            state.navigation[\.path].removeLast()
            XCTAssertEqual(state.navigation.value.path, originalPath)
            XCTAssertEqual(state.balance.value.query.search, "balance search")
            XCTAssertEqual(state.transactions.value.query.search, "general search")
        }
    }

    func testLeavingListInvalidatesObsoleteCompletionAndAllowsCorrectPageRetry() async {
        let repository = HistoryListDouble()
        await withHistory(repository) { _, _ in
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            repository.started = expectation(description: "First page starts")
            let old = Task { await list.loadNextPage() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            let pending = repository.pending
            list.cancelLoading()
            XCTAssertFalse(list.isLoading)
            repository.started = nil
            repository.rows = [historyTransaction("current")]
            await list.loadNextPage()
            pending?.resume(returning: .init(list: [historyTransaction("obsolete")], nextPage: 2, isCached: true))
            await old.value
            XCTAssertEqual(list.rows?.map(\.id), ["current"])
            XCTAssertNil(list.nextPage)
            XCTAssertFalse(list.isCached)
            XCTAssertNil(list.error)
        }
    }

    func testCompleteListFollowsReturnedPagesAndKeepsQueuedDuplicatePresentation() async {
        let repository = HistoryListDouble()
        repository.pages = [
            1: .init(list: [historyTransaction("local", created: "2026-04-01T00:00:00Z", queued: true),
                            historyTransaction("first", created: "2026-05-01T00:00:00Z")], nextPage: 2, isCached: false),
            2: .init(list: [historyTransaction("local", created: "2026-04-01T00:00:00Z"),
                            historyTransaction("second", created: "2026-03-01T00:00:00Z", status: .rejected, action: .sell),
                            historyTransaction("other-commodity", commodity: "butter"),
                            historyTransaction("other-season", season: "new")], nextPage: 3, isCached: false),
            3: .init(list: [historyTransaction("third", created: "2026-02-01T00:00:00Z", status: .automatic),
                            historyTransaction("fourth", status: .recorded)], nextPage: nil, isCached: false)
        ]
        await withHistory(repository) { preview, state in
            await preview.loadHistory()
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await list.loadNextPage()
            await list.loadNextPage()
            await list.loadNextPage()
            await list.loadNextPage()
            XCTAssertEqual(repository.requestedPages, [1, 1, 2, 3])
            XCTAssertEqual(list.rows?.map(\.id), ["first", "local", "second", "third", "fourth"])
            XCTAssertEqual(list.rows?.first(where: { $0.id == "local" })?.persistingData.state, .onDisk)
            XCTAssertNil(list.nextPage)
            XCTAssertTrue(repository.queries.allSatisfy {
                $0 == TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
            })
            XCTAssertEqual(state.balance.value.query.search, "balance search")
            XCTAssertEqual(state.transactions.value.query.search, "general search")
        }
    }

    func testNextPageFailureAndRetryRetainRowsAndResumeWithoutSkipping() async {
        let repository = HistoryListDouble()
        repository.pages[1] = .init(list: [historyTransaction("first")], nextPage: 2, isCached: false)
        repository.pages[2] = .init(list: [historyTransaction("second")], nextPage: nil, isCached: false)
        await withHistory(repository) { _, _ in
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await list.loadNextPage()
            repository.error = URLError(.timedOut)
            await list.loadNextPage()
            XCTAssertEqual(list.rows?.map(\.id), ["first"])
            XCTAssertEqual(list.nextPage, 2)
            XCTAssertEqual(list.error, .loadFailed)
            XCTAssertFalse(list.isLoading)
            repository.error = nil
            await list.loadNextPage()
            XCTAssertEqual(repository.requestedPages, [1, 2], "Automatic footer triggers must leave the failure visible")
            XCTAssertEqual(list.error, .loadFailed)
            await list.retry()
            XCTAssertEqual(repository.requestedPages, [1, 2, 2])
            XCTAssertEqual(list.rows?.map(\.id), ["first", "second"])
            XCTAssertNil(list.error)
            XCTAssertNil(list.nextPage)
        }
    }

    func testCachedPartialHistoryMissingCacheAndKnownEmptyRemainDistinct() async {
        let repository = HistoryListDouble()
        repository.pages[1] = .init(list: [historyTransaction("cached")], nextPage: 2, isCached: true)
        await withHistory(repository, offline: true) { _, _ in
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await list.loadNextPage()
            XCTAssertTrue(repository.cacheOnly)
            XCTAssertTrue(list.isCached)
            repository.error = TransactionHistoryError.unavailableCache
            await list.loadNextPage()
            XCTAssertEqual(list.rows?.map(\.id), ["cached"])
            XCTAssertEqual(list.nextPage, 2)
            XCTAssertEqual(list.error, .unavailableCache)
            let missing = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await missing.loadNextPage()
            XCTAssertNil(missing.rows)
            XCTAssertEqual(missing.error, .unavailableCache)
            repository.error = nil
            repository.pages[2] = .init(list: [historyTransaction("older")], nextPage: nil, isCached: true)
            await list.retry()
            XCTAssertEqual(list.rows?.map(\.id), ["cached", "older"])
            XCTAssertNil(list.nextPage)
            repository.pages[1] = .init(list: [], nextPage: nil, isCached: true)
            await missing.retry()
            XCTAssertEqual(missing.rows, [])
            XCTAssertNil(missing.error)
            XCTAssertTrue(missing.isCached)
        }
    }

    func testConcurrentPageRequestsAndCancelledCompletionCannotAdvanceCursor() async {
        let repository = HistoryListDouble()
        repository.pages[1] = .init(list: [historyTransaction("first")], nextPage: 2, isCached: false)
        await withHistory(repository) { _, _ in
            let list = SourceTransactionsModule.ViewModel(commodityId: "bean", seasonId: "past")
            await list.loadNextPage()
            repository.started = expectation(description: "Next page starts")
            let request = Task { await list.loadNextPage() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            await list.loadNextPage()
            XCTAssertEqual(repository.requestedPages, [1, 2])
            request.cancel()
            repository.pending?.resume(returning: .init(list: [historyTransaction("cancelled")], nextPage: nil, isCached: true))
            await request.value
            XCTAssertEqual(list.rows?.map(\.id), ["first"])
            XCTAssertEqual(list.nextPage, 2)
            XCTAssertNil(list.error)
            XCTAssertFalse(list.isLoading)
            XCTAssertFalse(list.isCached)
            repository.started = nil
            repository.pages[2] = .init(list: [historyTransaction("second")], nextPage: nil, isCached: false)
            await list.loadNextPage()
            XCTAssertEqual(list.rows?.map(\.id), ["first", "second"])
        }
    }

    func testPreviewUsesExactPairAndNewestCreationAcrossDirectionsAndStatuses() async {
        let repository = HistoryListDouble()
        repository.rows = [
            historyTransaction("old", created: "2026-01-01T12:00:00.000Z", updated: "2026-09-01T12:00:00.000Z"),
            historyTransaction("other-commodity", commodity: "butter", created: "2026-09-01T12:00:00.000Z"),
            historyTransaction("other-season", season: "new", created: "2026-09-01T12:00:00.000Z"),
            historyTransaction("outgoing", created: "2026-04-01T12:00:00.000Z", status: .rejected, action: .sell),
            historyTransaction("recorded", created: "2026-03-01T12:00:00.000Z", status: .recorded),
            historyTransaction("automatic", created: "2026-02-01T12:00:00.000Z", status: .automatic)
        ]
        await withHistory(repository) { model, state in
            await model.loadHistory()
            XCTAssertEqual(model.history?.map(\.id), ["outgoing", "recorded", "automatic"])
            XCTAssertEqual(model.lastActivity, "2026-04-01T12:00:00.000Z")
            XCTAssertEqual(repository.query?.commodityId, "bean")
            XCTAssertEqual(repository.query?.exactSeasonId, "past")
            XCTAssertNil(repository.query?.action)
            XCTAssertTrue(repository.query?.filter.isEmpty == true)
            XCTAssertEqual(state.balance.value.query.search, "balance search")
            XCTAssertEqual(state.transactions.value.query.search, "general search")
        }
    }

    func testPreviewCountsFromZeroThroughMoreThanThree() async {
        for count in 0...5 {
            let repository = HistoryListDouble()
            repository.rows = (0..<count).map { historyTransaction("row-\($0)", created: "2026-01-0\($0 + 1)T12:00:00.000Z") }
            await withHistory(repository) { model, _ in
                await model.loadHistory()
                XCTAssertEqual(model.history?.count, min(3, count))
                XCTAssertEqual(model.lastActivity == nil, count == 0)
                XCTAssertNil(model.historyError)
                XCTAssertFalse(model.isHistoryLoading)
            }
        }
    }

    func testAllDirectionsStatusesAndKindsRemainVisible() async {
        for status in [TransactionModel.Status.pending, .accepted, .rejected, .noResponse, .recorded, .automatic] {
            for action in [TransactionModel.Action.buy, .sell] {
                let repository = HistoryListDouble()
                repository.rows = [TransactionModel.TransactionType.producer, .downstream, .conversion].map { type in
                    historyTransaction(type.rawValue, status: status, action: action, type: type)
                }
                await withHistory(repository) { model, _ in
                    await model.loadHistory()
                    XCTAssertEqual(model.history?.count, 3)
                    XCTAssertTrue(model.history?.allSatisfy { $0.status == status && $0.action == action } == true)
                }
            }
        }
    }

    func testRowNavigationPreservesPairAndIndependentFilters() async throws {
        let repository = HistoryListDouble()
        repository.rows = [historyTransaction("selected")]
        await withHistory(repository) { model, state in
            await model.loadHistory()
            let pair = model.row
            let path = state.navigation.value.path
            model.openTransaction(repository.rows[0])
            XCTAssertEqual(state.navigation.value.path.last?.screen, .transactionDetails(transactionId: "selected"))
            state.navigation[\.path].removeLast()
            XCTAssertEqual(state.navigation.value.path, path)
            XCTAssertEqual(model.row, pair)
            XCTAssertEqual(state.balance.value.query.search, "balance search")
            XCTAssertEqual(state.transactions.value.query.search, "general search")
            model.openTransaction(historyTransaction("unrelated"))
            XCTAssertEqual(state.navigation.value.path, path)
        }
    }

    func testOfflineMissingCacheIsNotEmptyAndRetryRetainsSummary() async {
        let repository = HistoryListDouble()
        repository.error = TransactionHistoryError.unavailableCache
        await withHistory(repository, offline: true) { model, _ in
            let summary = model.row
            await model.loadHistory()
            XCTAssertTrue(repository.cacheOnly)
            XCTAssertNil(model.history)
            XCTAssertNil(model.lastActivity)
            XCTAssertEqual(model.historyError, .unavailableCache)
            XCTAssertEqual(model.row, summary)
            XCTAssertFalse(model.canConvert)
            repository.error = nil
            repository.isCached = true
            await model.loadHistory()
            XCTAssertEqual(model.history, [])
            XCTAssertNil(model.historyError)
            XCTAssertTrue(model.historyIsCached)
            XCTAssertFalse(model.canConvert)
        }
    }

    func testFailureAndCancellationRetainPreviouslyAvailableHistory() async {
        let repository = HistoryListDouble()
        repository.rows = [historyTransaction("saved")]
        repository.isCached = true
        await withHistory(repository) { model, _ in
            await model.loadHistory()
            repository.error = URLError(.timedOut)
            await model.loadHistory()
            XCTAssertEqual(model.historyError, .loadFailed)
            XCTAssertEqual(model.history?.map(\.id), ["saved"])
            XCTAssertTrue(model.historyIsCached)
            repository.error = CancellationError()
            await model.loadHistory()
            XCTAssertNil(model.historyError)
            XCTAssertEqual(model.history?.map(\.id), ["saved"])
            XCTAssertFalse(model.isHistoryLoading)
            repository.error = nil
            repository.isCached = false
            await model.loadHistory()
            XCTAssertFalse(model.historyIsCached)
        }
    }

    func testObsoleteAndCancelledResponsesCannotReplaceCurrentHistory() async {
        let repository = HistoryListDouble()
        await withHistory(repository) { model, _ in
            repository.started = expectation(description: "Old history request")
            let old = Task { await model.loadHistory() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            let oldContinuation = repository.pending
            repository.started = expectation(description: "Current history request")
            let current = Task { await model.loadHistory() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            repository.pending?.resume(returning: .init(list: [historyTransaction("current")], nextPage: nil, isCached: false))
            await current.value
            oldContinuation?.resume(returning: .init(list: [historyTransaction("obsolete")], nextPage: nil, isCached: true))
            await old.value
            XCTAssertEqual(model.history?.map(\.id), ["current"])
            XCTAssertFalse(model.historyIsCached)
            repository.started = expectation(description: "Cancelled retry")
            let retry = Task { await model.loadHistory() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            retry.cancel()
            repository.pending?.resume(throwing: URLError(.timedOut))
            await retry.value
            XCTAssertEqual(model.history?.map(\.id), ["current"])
            XCTAssertNil(model.historyError)
            XCTAssertFalse(model.isHistoryLoading)
        }
    }

    func testCrossFeatureUpdatesUseExactCommodityAndSeasonMatching() {
        var state = TransactionsState.initialState
        state.query = .init(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        state.list = .loaded(value: [])
        for item in [historyTransaction("other-commodity", commodity: "butter"),
                     historyTransaction("other-season", season: "new"), historyTransaction("unassigned", season: nil)] {
            state.updateList(with: item)
        }
        XCTAssertTrue(state.list.value?.isEmpty == true)
        state.updateList(with: historyTransaction("own", status: .automatic, action: .sell))
        XCTAssertEqual(state.list.value?.map(\.id), ["own"])
        state.updateList(with: historyTransaction("own", commodity: "butter"))
        XCTAssertTrue(state.list.value?.isEmpty == true)
    }

    private func withHistory(
        _ repository: HistoryListDouble, offline: Bool = false,
        operation: (BalanceDetailsModule.ViewModel, FilterAppStateTestDouble) async -> Void
    ) async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.balance[\.query] = .init(search: "balance search")
        state.transactions[\.query] = .init(search: "general search")
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.connectivity.register { HistoryConnectivity(offline: offline) }.scope(.unique)
        AppContainer.shared.commodityTransactionsInteractor.register {
            CommodityTransactionsInteractorImpl(repository: repository)
        }.scope(.unique)
        let row = SeasonalBalance(id: "pair", volume: 7,
            commodity: .init(id: "bean", code: "0901", name: "Ripe cherry", unit: "kg", group: .init(id: "coffee", name: "Coffee")),
            season: historySeason(), traceability: .partialTraceability, hasRecipe: true)
        await operation(.init(row: row, isCached: offline), state)
    }
}

@MainActor
final class HistoryListDouble: TransactionListRepository {
    var rows: [TransactionModel] = []
    var pages: [Int: TransactionListPage] = [:]
    var requestedPages: [Int] = []
    var queries: [TransactionListQuery] = []
    var error: Error?
    var isCached = false
    var query: TransactionListQuery?
    var cacheOnly = false
    var started: XCTestExpectation?
    var pending: CheckedContinuation<TransactionListPage, Error>?
    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        requestedPages.append(page)
        queries.append(query)
        self.query = query
        self.cacheOnly = cacheOnly
        if let started {
            return try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                started.fulfill()
            }
        }
        if let error { throw error }
        if let result = pages[page] { return result }
        return .init(list: .init(uniqueElements: rows), nextPage: nil, isCached: isCached)
    }
}

private final class HistoryConnectivity: Connectivity {
    let offline: Bool
    init(offline: Bool) { self.offline = offline }
    var isReachableValue: ConnectivityImpl.Status { offline ? .notReachable : .reachable(.ethernetOrWiFi) }
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> { Just(isReachableValue).eraseToAnyPublisher() }
    var isReachableFlag: Bool { !offline }
    func startObserving() { }
    func stopObserving() { }
}

func historySeason(_ id: String = "past") -> HarvestSeason {
    .init(id: id, name: "Coffee 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past)
}

func historyTransaction(
    _ id: String, commodity: String = "bean", season: String? = "past",
    created: String = "2026-01-01T12:00:00.000Z", updated: String? = nil,
    status: TransactionModel.Status = .accepted, action: TransactionModel.Action = .buy,
    type: TransactionModel.TransactionType = .producer, account: String = "account", queued: Bool = false
) -> TransactionModel {
    .init(id: id, createdAt: created, expiresAt: nil, updatedAt: updated, type: type, status: status, action: action,
          traceability: nil, location: nil, farmLatitude: nil, farmLongitude: nil, transactionLatitude: nil, transactionLongitude: nil,
          volume: 12, isBuyingFromFarmer: false,
          commodity: .init(id: commodity, code: "0901", name: "Ripe cherry", unit: "kg", balance: nil, hasRecipe: false,
                           group: .init(id: "coffee", name: "Coffee")),
          seller: nil, buyer: .init(id: account, username: "Test participant", gadgets: []), createdById: account,
          persistingData: queued ? .onDisk() : .sync(), harvestSeasonId: season, harvestSeason: season.map(historySeason))
}
