//
//  HomeViewModel.swift
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

import SwiftUI
import Combine
import Utility

private typealias Module = HomeModule

extension Module {
    @MainActor
    final class ViewModel: ViewModelProtocol {
        @Published private(set) var transactions: Loadable<IdentifiedArrayOf<TransactionModel>> = .notRequested
        @Published private(set) var showBottomLoader = false
        @Published private(set) var isCached = false
        @Published private(set) var hasListError = false
        @Published private(set) var appliedFilter = CommoditySeasonFilter()
        @Published var csvDocument: URLDocument?
        @Published var isExportingCSV = false
        @Published var showsCSVExporter = false
        @Published var filterSheet: CommoditySeasonFilterViewModel?
        @Published var selectedFilter: TransactionFilter = .all { didSet { criteriaChanged() } }
        @Published var searchText = "" { didSet { criteriaChanged() } }
        @Published var dates: Set<DateComponents> = [] { didSet { criteriaChanged() } }

        var hasCriteria: Bool { listInteractor.query != TransactionListQuery() }

        var filters: IdentifiedArrayOf<TransactionFilter> { .init(uniqueElements: TransactionFilter.allCases) }
        private var cancellable = CancelBag()
        private var exportTask: Task<Void, Never>?
        private var queryTask: Task<Void, Never>?

        @Inject(\.transactionDocumentsService) private var documentsService
        @Inject(\.appState) private var appState
        @Inject(\.permissionsService) private var permissionsService
        @Inject(\.transactionListInteractor) private var listInteractor
        @Inject(\.seasonCatalogueInteractor) private var catalogue
        @Inject(\.transactionsLocalRepository) private var transactionsLocalRepository

        init() {
            let query = listInteractor.query
            searchText = query.search
            appliedFilter = query.filter
            selectedFilter = query.action.map { $0 == .buy ? .bought : .sold } ?? .all
            dates = Set([query.createdAtFrom, query.createdAtTo].compactMap { $0 }
                .map { Calendar.current.dateComponents([.year, .month, .day], from: $0) })
            appState.transactions.state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.transactions = state.list
                    self?.isCached = state.isCached
                    self?.hasListError = state.hasListError
                }
                .store(in: cancellable)
            Task { [weak self] in
                await self?.permissionsService.requestNotifications()
                await self?.permissionsService.requestLocations(upTo: .authorizedAlways)
            }
        }

        func startCSVExport() {
            guard !isExportingCSV else { return }

            let query = listInteractor.query
            isExportingCSV = true
            exportTask = Task { [weak self] in
                guard let self else { return }

                defer { if !Task.isCancelled { self.isExportingCSV = false } }
                do {
                    let document = try await self.documentsService.downloadCSV(query: query)
                    try Task.checkCancellation()
                    self.csvDocument = document
                    self.showsCSVExporter = true
                } catch {
                    guard !Task.isCancelled else { return }

                    await self.appState.showError(message: error.localizedDescription)
                }
            }
        }

        func cancelCSVExport() {
            exportTask?.cancel()
            exportTask = nil
            isExportingCSV = false
        }

        func didFinishCSVExport(_ result: Result<URL, any Swift.Error>) {
            csvDocument = nil
            if case .failure(let error) = result {
                appState.showError(message: error.localizedDescription)
            }
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
            // SwiftUI can cancel its refresh action while the response is still being cached.
            // Keep this user-requested refresh owned here, like filter changes and retry actions.
            let task = Task { [listInteractor] in
                await listInteractor.refresh(cacheOnly: false)
            }
            queryTask = task
            await task.value
        }

        func didPullLoadNextPage() async {
            guard !showBottomLoader else { return }

            showBottomLoader = true
            defer { showBottomLoader = false }
            await listInteractor.loadNextPage()
        }

        func didTapOpenDetails(item: TransactionModel) async {
            do {
                let transaction = try await transactionsLocalRepository.fetchTransaction(by: item.id)
                let screen: Screen = .transactionDetails(transactionId: transaction.id)
                appState.navigation[\.path].append(.push(screen))
            } catch let error as TransactionsLocalRepositoryImpl.Error {
                switch error {
                    case .objectNotFound:
                        await appState.showError(message: Module.Error.transactionNotFound.localizedDescription)
                    case .cannotSaveObject:
                        await appState.showError(message: error.localizedDescription)
                }
            } catch {
                await appState.showError(message: error.localizedDescription)
            }
        }

        private func criteriaChanged(debounce: Bool = true) {
            let selectedDates = dates.compactMap { Calendar.current.date(from: $0) }.sorted()
            var query = TransactionListQuery()
            query.search = searchText
            query.action = selectedFilter == .all ? nil : selectedFilter == .bought ? .buy : .sell
            query.createdAtFrom = selectedDates.first
            query.createdAtTo = selectedDates.count > 1 ? selectedDates.last : nil
            query.filter = appliedFilter
            guard query != listInteractor.query else { return }

            listInteractor.setQuery(query)
            queryTask?.cancel()
            queryTask = Task { [weak self] in
                if debounce {
                    do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                }
                guard !Task.isCancelled else { return }

                await self?.listInteractor.refresh(cacheOnly: false)
            }
        }
    }
}
