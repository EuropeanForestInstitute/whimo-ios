//
//  BalanceListTests.swift
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
final class BalanceListTests: XCTestCase {
    func testRecreatingBalanceViewModelPreservesSearchAndAppliedSeason() {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let repository = ControlledBalanceRepository()
        let interactor = BalanceListInteractorImpl(appState: state, repository: repository)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { interactor }.scope(.unique)
        let season = HarvestSeason(id: "past", name: "Coffee 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past)
        let query = BalanceListQuery(search: "coffee", filter: .init(group: .init(id: "coffee", name: "Coffee"), season: season))
        interactor.setQuery(query)
        state.transactions[\.query] = .init(search: "cocoa")
        for _ in 0..<2 {
            let model = BalanceMainModule.ViewModel()
            XCTAssertEqual(model.searchText, "coffee")
            XCTAssertEqual(model.appliedFilter, query.filter)
            XCTAssertEqual(interactor.query, query, "Restoring a screen must not emit an empty filter query")
            XCTAssertEqual(state.transactions.value.query.search, "cocoa")
        }
    }

    func testConversionEntryRetainsTappedCommodityQuantityAndSeason() {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let repository = ControlledBalanceRepository()
        let interactor = BalanceListInteractorImpl(appState: state, repository: repository)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { interactor }.scope(.unique)
        let model = BalanceMainModule.ViewModel()
        let season = HarvestSeason(id: "past", name: "Coffee 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past)
        let row = SeasonalBalance(id: "balance-past", volume: 7,
            commodity: .init(id: "bean", code: "0901", name: "Ripe cherry", unit: "kg", group: .init(id: "coffee", name: "Coffee")),
            season: season, traceability: nil, hasRecipe: true)
        model.convert(row)
        guard case .convertCommodityList(let commodity, let capturedSeason) = state.navigation.value.path.last?.screen else {
            return XCTFail("Recipe selection must receive the tapped balance row")
        }
        XCTAssertEqual(commodity.id, "bean")
        XCTAssertEqual(commodity.balance, 7)
        XCTAssertEqual(capturedSeason?.id, "past")
    }

    func testDetailsEntryPreservesTappedRowAndIndependentQueries() {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let interactor = BalanceListInteractorImpl(appState: state, repository: ControlledBalanceRepository())
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { interactor }.scope(.unique)
        interactor.setQuery(.init(search: "coffee"))
        state.transactions[\.query] = .init(search: "cocoa")
        let model = BalanceMainModule.ViewModel()
        let row = SeasonalBalance(id: "bean-past", volume: 7,
            commodity: .init(id: "bean", code: "0901", name: "Cherry", unit: "kg", group: .init(id: "coffee", name: "Coffee")),
            season: .init(id: "past", name: "Coffee 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past),
            traceability: .partialTraceability, hasRecipe: true)
        model.openDetails(row)
        guard case .balanceDetails(let snapshot, let isCached) = state.navigation.value.path.last?.screen else {
            return XCTFail("The selected row must open Balance details")
        }
        XCTAssertEqual(snapshot, row)
        XCTAssertFalse(isCached)
        state.navigation[\.path].removeLast()
        XCTAssertEqual(interactor.query.search, "coffee")
        XCTAssertEqual(state.transactions.value.query.search, "cocoa")
    }

    func testCancellationRestoresRetryableStateWithoutAnError() async {
        let state = FilterAppStateTestDouble()
        let repository = ControlledBalanceRepository()
        let interactor = BalanceListInteractorImpl(appState: state, repository: repository)
        let task = Task { await interactor.refresh(cacheOnly: false) }
        let call = await repository.nextCall()
        task.cancel()
        await repository.complete(call.id, result: .failure(CancellationError()))
        await task.value
        XCTAssertFalse(state.balance.value.hasListError)
        XCTAssertFalse(state.balance.value.list.isLoading)
    }

    func testObsoleteResponseCannotReplaceIndependentFilterOrPagination() async {
        let state = FilterAppStateTestDouble()
        state.transactions[\.query] = .init(search: "transactions")
        let repository = ControlledBalanceRepository()
        let interactor = BalanceListInteractorImpl(appState: state, repository: repository)
        let old = Task { await interactor.refresh(cacheOnly: false) }
        let first = await repository.nextCall()
        let query = BalanceListQuery(search: "cocoa", filter: .init(group: .init(id: "group", name: "Cocoa")))
        interactor.setQuery(query)
        let current = Task { await interactor.refresh(cacheOnly: false) }
        let second = await repository.nextCall()
        XCTAssertEqual(second.query, query)
        await repository.complete(second.id, result: .success(page(1, next: 2)))
        await current.value
        await repository.complete(first.id, result: .failure(SeasonalBalanceError.unavailableCache))
        await old.value
        XCTAssertEqual(state.balance.value.query, query)
        XCTAssertEqual(state.transactions.value.query.search, "transactions")
        XCTAssertFalse(state.balance.value.hasListError)
        let next = Task { await interactor.loadNextPage() }
        let third = await repository.nextCall()
        XCTAssertEqual(third.page, 2)
        await repository.complete(third.id, result: .failure(SeasonalBalanceError.unavailableCache))
        await next.value
        XCTAssertTrue(state.balance.value.list.isLoaded)
        XCTAssertTrue(state.balance.value.hasListError)
        XCTAssertEqual(BalanceState.initialState.query, BalanceListQuery())
    }

    private func page(_ number: Int, next: Int?) -> SeasonalBalancePage {
        .init(rows: [], pagination: .init(pageSize: 20, nextPage: next, previousPage: nil, count: 0, totalPages: 1, page: number),
              message: nil, success: true)
    }
}

private actor ControlledBalanceRepository: SeasonalBalanceRepository {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance { throw SeasonalBalanceError.incompleteResponse }

    struct Call {
        let id: UUID
        let query: BalanceListQuery
        let page: Int
    }
    private var continuations: [UUID: CheckedContinuation<SeasonalBalancePage, Error>] = [:]
    private var calls: [Call] = []
    private var waiter: CheckedContinuation<Call, Never>?

    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
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

    func complete(_ id: UUID, result: Result<SeasonalBalancePage, Error>) {
        continuations.removeValue(forKey: id)?.resume(with: result)
    }
}
