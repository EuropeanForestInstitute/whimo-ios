//
//  BalanceMainViewModel.swift
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
import Combine
import Utility

extension BalanceMainModule {
    @MainActor
    final class ViewModel: ViewModelProtocol {
        @Published private(set) var balances: Loadable<IdentifiedArrayOf<SeasonalBalance>> = .notRequested
        @Published private(set) var isCached = false
        @Published private(set) var hasListError = false
        @Published private(set) var showBottomLoader = false
        @Published private(set) var connectionReachable = true
        @Published private(set) var appliedFilter = CommoditySeasonFilter()
        @Published var filterSheet: CommoditySeasonFilterViewModel?
        @Published var searchText = "" { didSet { criteriaChanged() } }

        private let cancellable = CancelBag()
        private var activationTask: Task<Void, Never>?
        private var queryTask: Task<Void, Never>?
        @Inject(\.appState) private var appState
        @Inject(\.balanceListInteractor) private var interactor
        @Inject(\.seasonCatalogueInteractor) private var catalogue
        @Inject(\.connectivity) private var connectivity

        var hasCriteria: Bool { !searchText.isEmpty || !appliedFilter.isEmpty }

        init() {
            appliedFilter = interactor.query.filter
            searchText = interactor.query.search
            appState.balance.state.receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.balances = state.list
                    self?.isCached = state.isCached
                    self?.hasListError = state.hasListError
                }
                .store(in: cancellable)
            appState.system.state.map(\.selectedTab).removeDuplicates()
                .receive(on: DispatchQueue.main)
                .filter { $0 == .balance }
                .sink { [weak self] _ in
                    guard let self else { return }

                    self.activationTask?.cancel()
                    self.activationTask = Task { [weak self] in await self?.interactor.refresh(cacheOnly: false) }
                }
                .store(in: cancellable)
            connectivity.isReachable.receive(on: DispatchQueue.main)
                .sink { [weak self] status in self?.connectionReachable = status != .notReachable }
                .store(in: cancellable)
        }

        func openFilters() {
            filterSheet = .init(applied: appliedFilter, catalogue: catalogue) { [weak self] filter in
                guard let self else { return }

                self.appliedFilter = filter
                self.filterSheet = nil
                self.criteriaChanged(debounce: false)
            }
        }

        func clearFilter() {
            appliedFilter = .init()
            criteriaChanged(debounce: false)
        }

        func didPullRefresh() async {
            queryTask?.cancel()
            await interactor.refresh(cacheOnly: false)
        }

        func loadNextPage() async {
            guard !showBottomLoader else { return }

            showBottomLoader = true
            defer { showBottomLoader = false }
            await interactor.loadNextPage()
        }

        func openDetails(_ row: SeasonalBalance) {
            appState.navigation[\.path].append(.push(.balanceDetails(row: row, isCached: isCached || !connectionReachable)))
        }

        func convert(_ row: SeasonalBalance) {
            guard connectionReachable, !isCached, row.hasRecipe, let season = row.season else { return }

            appState.navigation[\.path].append(.push(.convertCommodityList(commodity: row.conversionCommodity, season: season)))
        }

        private func criteriaChanged(debounce: Bool = true) {
            let query = BalanceListQuery(search: searchText, filter: appliedFilter)
            guard query != interactor.query else { return }

            interactor.setQuery(query)
            queryTask?.cancel()
            queryTask = Task { [weak self] in
                if debounce {
                    do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                }
                guard !Task.isCancelled else { return }

                await self?.interactor.refresh(cacheOnly: false)
            }
        }
    }
}
