//
//  BalanceDetailsTests.swift
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
import CommonUI
@testable import Whimo

@MainActor
final class BalanceDetailsTests: XCTestCase {
    func testRefreshReplacesSummaryPreviewAndLastActivityForFixedPair() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: .partialTraceability, isCached: true)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("old")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, state, _ in
            await model.refresh()
            repository.result = .success(.init(volume: 4, traceability: .fullTraceability, isCached: false))
            history.rows = [historyTransaction("new", created: "2026-09-01T00:00:00.000Z"),
                            historyTransaction("wrong-pair", season: "new", created: "2026-09-02T00:00:00.000Z")]
            await model.refresh()
            XCTAssertEqual(model.row.volume, 4)
            XCTAssertEqual(model.row.traceability, .fullTraceability)
            XCTAssertEqual(model.history?.map(\.id), ["new"])
            XCTAssertEqual(model.lastActivity, "2026-09-01T00:00:00.000Z")
            XCTAssertFalse(model.isCached)
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.isHistoryLoading)
            XCTAssertEqual(repository.request?.commodityId, "bean")
            XCTAssertEqual(repository.request?.seasonId, "past")
            XCTAssertEqual(state.balance.value.query.search, "coffee")
            XCTAssertEqual(state.transactions.value.query.search, "cocoa")
        }
    }

    func testLeavingDuringRefreshAllowsReentryAndRejectsOldSummaryAndHistory() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: .partialTraceability, isCached: false)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("saved")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, _, _ in
            await model.refresh()
            repository.started = expectation(description: "Suspended balance")
            history.started = expectation(description: "Suspended history")
            let old = Task { await model.refresh() }
            if let balanceStarted = repository.started, let historyStarted = history.started {
                await fulfillment(of: [balanceStarted, historyStarted], timeout: 2)
            }
            let oldBalance = repository.pending
            let oldHistory = history.pending
            XCTAssertEqual(model.row.volume, 7)
            XCTAssertEqual(model.history?.map(\.id), ["saved"])
            model.cancelLoading()
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.isHistoryLoading)
            repository.started = nil
            history.started = nil
            repository.result = .success(.init(volume: 2, traceability: .fullTraceability, isCached: false))
            history.rows = [historyTransaction("current")]
            await model.refresh()
            oldBalance?.resume(returning: .init(volume: 99, traceability: nil, isCached: true))
            oldHistory?.resume(returning: .init(list: [historyTransaction("obsolete")], nextPage: nil, isCached: true))
            await old.value
            XCTAssertEqual(model.row.volume, 2)
            XCTAssertEqual(model.row.traceability, .fullTraceability)
            XCTAssertEqual(model.history?.map(\.id), ["current"])
            XCTAssertFalse(model.isCached)
            XCTAssertFalse(model.historyIsCached)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertNil(model.historyError)
        }
    }

    func testRefreshRetainsEachFailedAreaAndRecoversAfterConnectivityReturns() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: .partialTraceability, isCached: true)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("cached")]
        history.isCached = true
        await withModel(row: makeRow(), isCached: true, offline: true, repository: repository, history: history) { model, _, connectivity in
            await model.refresh()
            XCTAssertTrue(history.cacheOnly)
            XCTAssertTrue(model.showsCachedNotice)
            XCTAssertFalse(model.canConvert)
            repository.result = .failure(SeasonalBalanceError.unavailableCache)
            history.error = TransactionHistoryError.unavailableCache
            await model.refresh()
            XCTAssertEqual(model.row.volume, 7)
            XCTAssertEqual(model.history?.map(\.id), ["cached"])
            XCTAssertTrue(model.isCached)
            XCTAssertTrue(model.historyIsCached)
            XCTAssertTrue(model.hasLoadError)
            XCTAssertEqual(model.historyError, .unavailableCache)

            connectivity.status.send(.reachable(.ethernetOrWiFi))
            history.error = nil
            history.isCached = false
            history.rows = [historyTransaction("online", created: "2026-09-02T00:00:00.000Z")]
            await model.refresh()
            XCTAssertEqual(model.row.volume, 7)
            XCTAssertTrue(model.hasLoadError)
            XCTAssertTrue(model.isCached)
            XCTAssertEqual(model.history?.map(\.id), ["online"])
            XCTAssertEqual(model.lastActivity, "2026-09-02T00:00:00.000Z")
            XCTAssertFalse(model.historyIsCached)
            XCTAssertFalse(history.cacheOnly)

            repository.result = .success(.init(volume: 3, traceability: .fullTraceability, isCached: false))
            history.error = TransactionHistoryError.incompleteResponse
            await model.refresh()
            XCTAssertEqual(model.row.volume, 3)
            XCTAssertEqual(model.row.traceability, .fullTraceability)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertFalse(model.isCached)
            XCTAssertEqual(model.history?.map(\.id), ["online"])
            XCTAssertEqual(model.historyError, .incompleteResponse)
            history.error = nil
            await model.refresh()
            XCTAssertNil(model.historyError)
            XCTAssertFalse(model.isHistoryLoading)
            XCTAssertFalse(model.isLoading)
        }
    }

    func testOnlyCompleteEmptyAndZeroReplaceLoadedData() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: .partialTraceability, isCached: false)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("old")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, _, _ in
            await model.refresh()
            for error in [TransactionHistoryError.incompleteResponse, .unavailableCache, .loadFailed] {
                repository.result = .failure(SeasonalBalanceError.incompleteResponse)
                history.error = error
                history.rows = []
                await model.refresh()
                XCTAssertEqual(model.row.volume, 7)
                XCTAssertEqual(model.row.traceability, .partialTraceability)
                XCTAssertEqual(model.history?.map(\.id), ["old"])
                XCTAssertNotNil(model.lastActivity)
            }
            repository.result = .success(.init(volume: 0, traceability: nil, isCached: false))
            history.error = nil
            await model.refresh()
            XCTAssertEqual(model.row.volume, 0)
            XCTAssertNil(model.row.traceability)
            XCTAssertEqual(model.history, [])
            XCTAssertNil(model.lastActivity)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertNil(model.historyError)
        }
    }

    func testTransactionAndConversionReturnAndReentryRefreshWithoutChangingQueries() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: nil, isCached: false)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("preview")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, state, _ in
            state.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true), .push(.balanceDetails(row: model.row, isCached: false))]
            let detailsPath = state.navigation.value.path
            let balanceQuery = state.balance.value.query
            let transactionQuery = state.transactions.value.query
            await model.refresh()
            model.openTransaction(history.rows[0])
            XCTAssertEqual(state.navigation.value.path.last?.screen, .transactionDetails(transactionId: "preview"))
            model.cancelLoading()
            state.transactions.dispatch { $0.updateList(with: historyTransaction("unrelated", season: "other")) }
            repository.result = .success(.init(volume: 6, traceability: .fullTraceability, isCached: false))
            history.rows = [historyTransaction("after-transaction", created: "2026-09-01T00:00:00.000Z")]
            state.navigation[\.path].removeLast()
            await model.refresh()
            XCTAssertEqual(model.row.volume, 6)
            XCTAssertEqual(model.history?.map(\.id), ["after-transaction"])
            XCTAssertEqual(state.navigation.value.path, detailsPath)
            model.convert()
            guard case .convertCommodityList(let commodity, let season) = state.navigation.value.path.last?.screen else {
                return XCTFail("Conversion must retain the existing recipe route")
            }
            XCTAssertEqual(commodity.balance, 6)
            XCTAssertEqual(season?.id, "past")
            model.cancelLoading()
            repository.result = .success(.init(volume: 4, traceability: .conditionalTraceability, isCached: false))
            history.rows = [historyTransaction("after-conversion", created: "2026-09-02T00:00:00.000Z")]
            state.navigation[\.path].removeLast()
            await model.refresh()
            XCTAssertEqual(state.navigation.value.path, detailsPath)
            XCTAssertEqual(model.row.volume, 4)
            XCTAssertEqual(model.history?.map(\.id), ["after-conversion"])
            let reopened = BalanceDetailsModule.ViewModel(row: makeRow(), isCached: false)
            await reopened.refresh()
            XCTAssertEqual(reopened.row.volume, 4)
            XCTAssertEqual(reopened.history?.map(\.id), ["after-conversion"])
            XCTAssertEqual(state.balance.value.query, balanceQuery)
            XCTAssertEqual(state.transactions.value.query, transactionQuery)
        }
    }

    func testRepeatedRefreshAndCancellationRetainDataAndAllowRetry() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: nil, isCached: false)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("saved")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, _, _ in
            await model.refresh()
            repository.started = expectation(description: "Balance refresh starts once")
            history.started = expectation(description: "History refresh starts once")
            let refresh = Task { await model.refresh() }
            if let balanceStarted = repository.started, let historyStarted = history.started {
                await fulfillment(of: [balanceStarted, historyStarted], timeout: 2)
            }
            await model.refresh()
            XCTAssertTrue(model.isLoading)
            XCTAssertTrue(model.isHistoryLoading)
            XCTAssertEqual(model.row.volume, 7)
            XCTAssertEqual(model.history?.map(\.id), ["saved"])
            refresh.cancel()
            repository.pending?.resume(throwing: URLError(.timedOut))
            history.pending?.resume(returning: .init(list: [], nextPage: nil, isCached: true))
            await refresh.value
            XCTAssertEqual(model.row.volume, 7)
            XCTAssertEqual(model.history?.map(\.id), ["saved"])
            XCTAssertFalse(model.hasLoadError)
            XCTAssertNil(model.historyError)
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.isHistoryLoading)
            repository.started = nil
            history.started = nil
            repository.result = .success(.init(volume: 5, traceability: nil, isCached: false))
            history.rows = [historyTransaction("retry")]
            await model.refresh()
            XCTAssertEqual(model.row.volume, 5)
            XCTAssertEqual(model.history?.map(\.id), ["retry"])
        }
    }

    func testRetryAfterHistoryFailureReplacesStillPendingBalanceRefresh() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 7, traceability: nil, isCached: false)))
        let history = HistoryListDouble()
        history.rows = [historyTransaction("saved")]
        await withModel(row: makeRow(), repository: repository, history: history) { model, _, _ in
            await model.reload()
            repository.started = expectation(description: "Balance suspended while history fails")
            history.started = expectation(description: "History request starts")
            let old = Task { await model.reload() }
            if let balanceStarted = repository.started, let historyStarted = history.started {
                await fulfillment(of: [balanceStarted, historyStarted], timeout: 2)
            }
            let oldBalance = repository.pending
            let failed = expectation(description: "History failure is visible")
            let observation = model.$historyError.dropFirst().sink { if $0 != nil { failed.fulfill() } }
            history.pending?.resume(throwing: TransactionHistoryError.loadFailed)
            await fulfillment(of: [failed], timeout: 2)
            observation.cancel()
            XCTAssertTrue(model.isLoading)
            old.cancel()
            repository.started = nil
            history.started = nil
            repository.result = .success(.init(volume: 3, traceability: .fullTraceability, isCached: false))
            history.rows = [historyTransaction("retried")]
            await model.reload()
            XCTAssertEqual(model.row.volume, 3)
            XCTAssertEqual(model.history?.map(\.id), ["retried"])
            XCTAssertNil(model.historyError)
            oldBalance?.resume(throwing: URLError(.timedOut))
            await old.value
            XCTAssertFalse(model.hasLoadError)
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.isHistoryLoading)
        }
    }

    func testExactLoadUsesTappedPairAndPreservesOtherQueries() async {
        let row = makeRow()
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 4, traceability: .fullTraceability, isCached: false)))
        await withModel(row: row, repository: repository) { model, state, _ in
            XCTAssertEqual(model.row, row, "The tapped snapshot is immediately readable")
            await model.load()
            XCTAssertEqual(repository.request?.commodityId, "bean")
            XCTAssertEqual(repository.request?.seasonId, "past")
            XCTAssertEqual(model.row.volume, 4)
            XCTAssertEqual(model.row.traceability, .fullTraceability)
            XCTAssertEqual(model.row.commodity, row.commodity)
            XCTAssertEqual(model.row.season, row.season)
            XCTAssertEqual(state.balance.value.query.search, "coffee")
            XCTAssertEqual(state.transactions.value.query.search, "cocoa")
        }
    }

    func testCompleteZeroClearsTraceabilityAndConversionUsesThatQuantity() async {
        let repository = DetailsBalanceRepository(result: .success(.init(volume: 0, traceability: nil, isCached: false)))
        await withModel(row: makeRow(), repository: repository) { model, state, _ in
            await model.load()
            XCTAssertEqual(model.row.volume, 0)
            XCTAssertNil(model.row.traceability, "Missing backend traceability must not become Incomplete")
            XCTAssertFalse(model.hasLoadError)
            model.convert()
            guard case .convertCommodityList(let commodity, let season) = state.navigation.value.path.last?.screen else {
                return XCTFail("A known zero retains the existing recipe availability rules")
            }
            XCTAssertEqual(commodity.id, "bean")
            XCTAssertEqual(commodity.balance, 0)
            XCTAssertEqual(season?.id, "past")
        }
    }

    func testUnavailableIncompleteAndFailedLoadsKeepSnapshotAndAllowRetry() async {
        let failures: [Error] = [SeasonalBalanceError.unavailableCache, SeasonalBalanceError.incompleteResponse, URLError(.timedOut)]
        for error in failures {
            let repository = DetailsBalanceRepository(result: .failure(error))
            let row = makeRow()
            await withModel(row: row, isCached: true, repository: repository) { model, _, _ in
                await model.load()
                XCTAssertEqual(model.row, row)
                XCTAssertTrue(model.hasLoadError)
                XCTAssertTrue(model.showsCachedNotice)
                XCTAssertFalse(model.canConvert)
                repository.result = .success(.init(volume: 5, traceability: .conditionalTraceability, isCached: false))
                await model.load()
                XCTAssertEqual(model.row.volume, 5)
                XCTAssertEqual(model.row.traceability, .conditionalTraceability)
                XCTAssertFalse(model.hasLoadError)
                XCTAssertFalse(model.isCached)
                XCTAssertTrue(model.canConvert)
            }
        }
    }

    func testMissingSeasonRetainsSnapshotWithoutWideningRequestOrAllowingConversion() async {
        let row = makeRow(season: false)
        let repository = DetailsBalanceRepository(result: .failure(SeasonalBalanceError.incompleteResponse))
        await withModel(row: row, repository: repository) { model, state, _ in
            await model.load()
            XCTAssertEqual(model.row, row)
            XCTAssertNil(repository.request)
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertFalse(model.canConvert)
            let path = state.navigation.value.path
            model.convert()
            XCTAssertEqual(state.navigation.value.path, path)
        }
    }

    func testCachedOfflineAndNoRecipeEachPreventConversion() async {
        for scenario in 0..<3 {
            let repository = DetailsBalanceRepository(result: .success(.init(volume: 3, traceability: nil, isCached: scenario == 0)))
            await withModel(row: makeRow(hasRecipe: scenario != 2), isCached: scenario == 0,
                            offline: scenario == 1, repository: repository) { model, state, _ in
                XCTAssertFalse(model.canConvert)
                await model.load()
                XCTAssertEqual(model.row.volume, 3)
                XCTAssertFalse(model.canConvert)
                XCTAssertEqual(model.showsCachedNotice, scenario != 2)
                let path = state.navigation.value.path
                model.convert()
                XCTAssertEqual(state.navigation.value.path, path)
            }
        }
    }

    func testConnectivityLossImmediatelyPreventsConversionBeforePublisherDelivery() async {
        let repository = DetailsBalanceRepository(result: .failure(SeasonalBalanceError.unavailableCache))
        await withModel(row: makeRow(), repository: repository) { model, state, connectivity in
            XCTAssertTrue(model.canConvert)
            connectivity.status.send(.notReachable)
            let path = state.navigation.value.path
            model.convert()
            XCTAssertEqual(state.navigation.value.path, path)
        }
    }

    func testCancelledLoadKeepsSnapshotWithoutErrorAndCanBeRetried() async {
        let row = makeRow()
        let repository = DetailsBalanceRepository(result: .failure(CancellationError()))
        await withModel(row: row, repository: repository) { model, _, _ in
            await model.load()
            XCTAssertEqual(model.row, row)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertFalse(model.isLoading)
            repository.result = .success(.init(volume: 9, traceability: nil, isCached: false))
            await model.load()
            XCTAssertEqual(model.row.volume, 9)
        }
    }

    func testCancelledRetryIgnoresLateFailure() async {
        let row = makeRow()
        let repository = DetailsBalanceRepository(result: .failure(SeasonalBalanceError.unavailableCache))
        await withModel(row: row, repository: repository) { model, _, _ in
            await model.load()
            XCTAssertTrue(model.hasLoadError)
            repository.started = expectation(description: "Retry started")
            let retry = Task { await model.load() }
            if let started = repository.started { await fulfillment(of: [started], timeout: 2) }
            retry.cancel()
            repository.pending?.resume(throwing: SeasonalBalanceError.incompleteResponse)
            await retry.value
            XCTAssertEqual(model.row, row)
            XCTAssertFalse(model.hasLoadError)
            XCTAssertFalse(model.isLoading)
        }
    }

    private func makeRow(season: Bool = true, hasRecipe: Bool = true) -> SeasonalBalance {
        .init(id: "bean-past", volume: 7,
              commodity: .init(id: "bean", code: "0901", name: "Cherry", unit: "kg", group: .init(id: "coffee", name: "Coffee")),
              season: season ? .init(id: "past", name: "Coffee 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past) : nil,
              traceability: .partialTraceability, hasRecipe: hasRecipe)
    }

    private func withModel(
        row: SeasonalBalance, isCached: Bool = false, offline: Bool = false,
        repository: DetailsBalanceRepository, history: HistoryListDouble? = nil,
        operation: (BalanceDetailsModule.ViewModel, FilterAppStateTestDouble, DetailsConnectivity) async -> Void
    ) async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.balance[\.query] = .init(search: "coffee")
        state.transactions[\.query] = .init(search: "cocoa")
        let connectivity = DetailsConnectivity(offline: offline)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.connectivity.register { connectivity }.scope(.unique)
        AppContainer.shared.alertManager.register { AlertManager() }.scope(.singleton)
        AppContainer.shared.balanceListInteractor.register {
            BalanceListInteractorImpl(appState: state, repository: repository)
        }.scope(.unique)
        let history = history ?? HistoryListDouble()
        AppContainer.shared.commodityTransactionsInteractor.register {
            CommodityTransactionsInteractorImpl(repository: history)
        }.scope(.unique)
        let model = BalanceDetailsModule.ViewModel(row: row, isCached: isCached)
        await operation(model, state, connectivity)
    }
}

private final class DetailsBalanceRepository: SeasonalBalanceRepository {
    var result: Result<ExactSeasonalBalance, Error>
    var started: XCTestExpectation?
    var pending: CheckedContinuation<ExactSeasonalBalance, Error>?
    private(set) var request: (commodityId: String, seasonId: String)?

    init(result: Result<ExactSeasonalBalance, Error>) { self.result = result }

    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        request = (commodityId, seasonId)
        if let started {
            return try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                started.fulfill()
            }
        }
        return try result.get()
    }

    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
}

private final class DetailsConnectivity: Connectivity {
    let status: CurrentValueSubject<ConnectivityImpl.Status, Never>
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> { status.eraseToAnyPublisher() }
    var isReachableValue: ConnectivityImpl.Status { status.value }
    var isReachableFlag: Bool { status.value != .notReachable }

    init(offline: Bool) { status = .init(offline ? .notReachable : .reachable(.ethernetOrWiFi)) }
    func startObserving() { }
    func stopObserving() { }
}
