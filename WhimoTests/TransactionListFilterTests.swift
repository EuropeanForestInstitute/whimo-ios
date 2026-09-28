//
//  TransactionListFilterTests.swift
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
import CommonUI
import Utility
@testable import Whimo

@MainActor
final class TransactionListFilterTests: XCTestCase {
    func testCrossFeatureUpdateCannotInsertTransactionOutsideAppliedSeason() {
        var state = TransactionsState.initialState
        state.list = .loaded(value: [])
        let season = HarvestSeason(id: "season", name: "Season", startDate: .distantPast, endDate: .distantFuture, status: .active)
        state.query.filter = .init(group: .init(id: "0", name: "Group"), season: season)
        var transaction = TransactionModel(
            id: "transaction", createdAt: "2026-01-01", expiresAt: nil, updatedAt: nil,
            type: .producer, status: .accepted, action: .buy, traceability: nil, location: nil,
            farmLatitude: nil, farmLongitude: nil, transactionLatitude: nil, transactionLongitude: nil,
            volume: 1, isBuyingFromFarmer: false, commodity: .initialState, seller: nil, buyer: nil,
            createdById: nil, persistingData: .onDisk()
        )
        state.updateList(with: transaction)
        XCTAssertTrue(state.list.value?.isEmpty == true)
        transaction.harvestSeasonId = "season"
        state.updateList(with: transaction)
        XCTAssertEqual(state.list.value?.map(\.id), ["transaction"])
        state.list.setIsLoading()
        transaction.harvestSeasonId = "different-season"
        state.updateList(with: transaction)
        XCTAssertTrue(state.list.isLoading)
        XCTAssertTrue(state.list.value?.isEmpty == true)
    }

    func testObsoleteResponseCannotReplaceNewQueryOrPagination() async {
        let state = FilterAppStateTestDouble()
        let repository = ControlledListRepository()
        let interactor = TransactionListInteractorImpl(appState: state, repository: repository)
        let old = Task { await interactor.refresh() }
        let first = await repository.nextCall()
        XCTAssertEqual(first.page, 1)
        var query = TransactionListQuery()
        query.search = "cocoa"
        query.filter = .init(group: .init(id: "group", name: "Cocoa"))
        interactor.setQuery(query)
        let current = Task { await interactor.refresh() }
        let second = await repository.nextCall()
        XCTAssertEqual(second.query, query)
        XCTAssertEqual(second.page, 1)
        await repository.complete(second.id, result: .success(.init(list: [], nextPage: 7, isCached: false)))
        await current.value
        await repository.complete(first.id, result: .success(.init(list: [], nextPage: 2, isCached: true)))
        await old.value
        XCTAssertEqual(state.transactions.value.query, query)
        XCTAssertFalse(state.transactions.value.isCached)
        XCTAssertTrue(state.transactions.value.list.isLoaded)
        let next = Task { await interactor.loadNextPage() }
        let third = await repository.nextCall()
        XCTAssertEqual(third.page, 7)
        XCTAssertEqual(third.query, query)
        await repository.complete(third.id, result: .success(.init(list: [], nextPage: nil, isCached: false)))
        await next.value
    }

    func testPaginationFailureRetainsLoadedValueAndExposesRetryState() async {
        let state = FilterAppStateTestDouble()
        let repository = ControlledListRepository()
        let interactor = TransactionListInteractorImpl(appState: state, repository: repository)
        let first = Task { await interactor.refresh() }
        let call = await repository.nextCall()
        await repository.complete(call.id, result: .success(.init(list: [], nextPage: 2, isCached: false)))
        await first.value
        let next = Task { await interactor.loadNextPage() }
        let page = await repository.nextCall()
        await repository.complete(page.id, result: .failure(CocoaError(.fileReadUnknown)))
        await next.value
        XCTAssertTrue(state.transactions.value.list.isLoaded)
        XCTAssertNotNil(state.transactions.value.list.value)
        XCTAssertTrue(state.transactions.value.hasListError)
        let retry = Task { await interactor.loadNextPage() }
        let retried = await repository.nextCall()
        XCTAssertEqual(retried.page, 2)
        await repository.complete(retried.id, result: .success(.init(list: [], nextPage: nil, isCached: false)))
        await retry.value
        XCTAssertFalse(state.transactions.value.hasListError)
    }

    func testCancelledRefreshRetainsRowsWithoutShowingLoadError() async {
        let state = FilterAppStateTestDouble()
        state.transactions.dispatch { $0.list = .loaded(value: []) }
        let repository = ControlledListRepository()
        let interactor = TransactionListInteractorImpl(appState: state, repository: repository)
        let refresh = Task { await interactor.refresh() }
        let call = await repository.nextCall()
        refresh.cancel()
        await repository.complete(call.id, result: .failure(CancellationError()))
        await refresh.value
        XCTAssertFalse(state.transactions.value.hasListError, "Cancelled pull to refresh must not show Unable to load transactions")
        XCTAssertTrue(state.transactions.value.list.isLoaded)

        let retry = Task { await interactor.refresh() }
        let retried = await repository.nextCall()
        await repository.complete(retried.id, result: .success(.init(list: [], nextPage: nil, isCached: false)))
        await retry.value
        XCTAssertFalse(state.transactions.value.hasListError)
    }

    func testTypingInvalidatesOldFailureBeforeDebouncedFetchStarts() async {
        let state = FilterAppStateTestDouble()
        let repository = ControlledListRepository()
        let interactor = TransactionListInteractorImpl(appState: state, repository: repository)
        let old = Task { await interactor.refresh() }
        let call = await repository.nextCall()
        var query = TransactionListQuery()
        query.search = "new"
        interactor.setQuery(query)
        await repository.complete(call.id, result: .failure(CocoaError(.fileReadUnknown)))
        await old.value
        XCTAssertNil(state.transactions.value.list.error)
        XCTAssertEqual(interactor.query.search, "new")
    }

    func testClearingOnlyGroupAndSeasonPreservesIndependentCriteria() {
        let state = FilterAppStateTestDouble()
        let interactor = TransactionListInteractorImpl(appState: state, repository: ControlledListRepository())
        var query = TransactionListQuery()
        query.search = "beans"
        query.action = .sell
        query.createdAtFrom = Date(timeIntervalSince1970: 1_767_225_600)
        query.createdAtTo = Date(timeIntervalSince1970: 1_769_904_000)
        query.filter = .init(group: .init(id: "group", name: "Cocoa"))
        interactor.setQuery(query)
        query.filter = .init()
        interactor.setQuery(query)
        XCTAssertTrue(interactor.query.filter.isEmpty)
        XCTAssertEqual(interactor.query.search, "beans")
        XCTAssertEqual(interactor.query.action, .sell)
        XCTAssertEqual(interactor.query.createdAtFrom, Date(timeIntervalSince1970: 1_767_225_600))
        XCTAssertEqual(interactor.query.createdAtTo, Date(timeIntervalSince1970: 1_769_904_000))
        XCTAssertTrue(FilterAppStateTestDouble().transactions.value.query.filter.isEmpty)
    }
}

private actor ControlledListRepository: TransactionListRepository {
    struct Call {
        let id: UUID
        let query: TransactionListQuery
        let page: Int
    }
    private var continuations: [UUID: CheckedContinuation<TransactionListPage, Error>] = [:]
    private var calls: [Call] = []
    private var waiter: CheckedContinuation<Call, Never>?

    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        try await withCheckedThrowingContinuation { continuation in
            let call = Call(id: UUID(), query: query, page: page)
            continuations[call.id] = continuation
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

    func complete(_ id: UUID, result: Result<TransactionListPage, Error>) {
        continuations.removeValue(forKey: id)?.resume(with: result)
    }
}

final class FilterAppStateTestDouble: AppState {
    let system: StateStore<SystemState> = .init(inititalValue: .test)
    let navigation: StateStore<NavigationState> = .init(inititalValue: .test)
    let transactions: StateStore<TransactionsState> = .init(inititalValue: .test)
    let balance: StateStore<BalanceState> = .init(inititalValue: .test)
    let createTransaction: StateStore<CreateTransactionState> = .init(inititalValue: .test)
    let createPassword: StateStore<CreatePasswordState> = .init(inititalValue: .test)
    let notifications: StateStore<NotificationsState> = .init(inititalValue: .test)
    let notificationsSettings: StateStore<NotificationsSettingsState> = .init(inititalValue: .test)
    let profile: StateStore<ProfileState> = .init(inititalValue: .test)

    func showInfo(message: String, hapticsEnabled: Bool) { }

    @MainActor
    func showInfo(message: String, hapticsEnabled: Bool) async { }

    @MainActor
    func replace(
        old oldToast: ToastValue?,
        new newToast: ToastValue,
        hapticsEnabled: Bool
    ) async -> ToastValue {
        newToast
    }

    func showError(
        message: String,
        button: ToastManager.ToastButton?,
        hapticsEnabled: Bool
    ) { }

    @MainActor
    func showError(
        message: String,
        button: ToastManager.ToastButton?,
        hapticsEnabled: Bool
    ) async { }
}
