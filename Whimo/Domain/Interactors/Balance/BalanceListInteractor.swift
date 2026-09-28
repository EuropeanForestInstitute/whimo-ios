//
//  BalanceListInteractor.swift
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

import Foundation
import Utility

protocol BalanceListInteractor {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance
    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance
    @MainActor
    var query: BalanceListQuery { get }
    @MainActor
    func setQuery(_ query: BalanceListQuery)
    @MainActor
    func refresh(cacheOnly: Bool) async
    @MainActor
    func loadNextPage() async
}

final class BalanceListInteractorImpl: BalanceListInteractor {
    private let businessDataContext: BusinessDataContext
    private let appState: AppState
    private let repository: SeasonalBalanceRepository
    @MainActor private var generation = UUID()
    @MainActor private var nextPage: Int?
    @MainActor private var isLoading = false

    init(appState: AppState, repository: SeasonalBalanceRepository,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.appState = appState
        self.repository = repository
    }

    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        try await businessDataContext.withCurrentGeneration {
            try await repository.exact(commodityId: commodityId, seasonId: seasonId)
        }
    }

    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        try await businessDataContext.withCurrentGeneration {
            try await repository.cachedExact(commodityId: commodityId, seasonId: seasonId)
        }
    }

    @MainActor
    var query: BalanceListQuery { appState.balance.value.query }

    @MainActor
    func setQuery(_ query: BalanceListQuery) {
        guard query != self.query else { return }

        generation = UUID()
        nextPage = nil
        isLoading = false
        appState.balance.dispatch { state in
            state.query = query
            state.pagination = nil
            state.list = .requested(lastValue: nil)
            state.isCached = false
            state.hasListError = false
        }
    }

    @MainActor
    func refresh(cacheOnly: Bool = false) async {
        generation = UUID()
        nextPage = nil
        await fetch(page: 1, cacheOnly: cacheOnly)
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoading, let nextPage, appState.balance.value.list.value != nil else { return }

        await fetch(page: nextPage, cacheOnly: appState.balance.value.isCached)
    }

    @MainActor
    private func fetch(page: Int, cacheOnly: Bool) async {
        guard let businessGeneration = try? businessDataContext.capture() else { return }

        let token = generation
        let query = query
        isLoading = true
        appState.balance.dispatch { state in
            state.list.setIsLoading()
            state.hasListError = false
        }
        defer { if generation == token { isLoading = false } }
        do {
            let response = try await BusinessDataContext.$requestGeneration.withValue(businessGeneration) {
                try await repository.page(query: query, page: page, cacheOnly: cacheOnly)
            }
            guard generation == token, (try? businessGeneration.whileCurrent { }) != nil else { return }

            if page > 1, response.isCached != appState.balance.value.isCached {
                await refresh(cacheOnly: response.isCached)
                return
            }
            nextPage = response.pagination.nextPage
            appState.balance.dispatch { state in
                var list = page == 1 ? IdentifiedArrayOf<SeasonalBalance>() : state.list.value ?? []
                for item in response.rows {
                    list[id: item.id] = item
                }
                state.list = .loaded(value: list)
                state.isCached = response.isCached
                state.pagination = response.pagination
            }
        } catch {
            guard generation == token, (try? businessGeneration.whileCurrent { }) != nil else { return }

            if error is CancellationError || Task.isCancelled {
                appState.balance.dispatch { state in
                    state.list = state.list.value.map { .loaded(value: $0) } ?? .notRequested
                }
                return
            }
            appState.balance.dispatch { state in
                state.hasListError = true
                if let previous = state.list.value {
                    state.list = .loaded(value: previous)
                } else {
                    state.list = .failed(error: error)
                }
            }
        }
    }
}
