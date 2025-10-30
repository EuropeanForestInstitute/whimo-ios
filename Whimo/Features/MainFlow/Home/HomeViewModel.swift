//
//  HomeViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
//
//  Copyright (c) 2025 EFI https://efi.int/
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
import RestClient
import Utility
import enum Resources.LocalizeKeys

private typealias Module = HomeModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        enum ListLoader {
            case top
            case bottom
        }

        // MARK: - Public Properties
        @Published private(set) var transactions: Loadable<IdentifiedArrayOf<TransactionModel>> = .notRequested
        @Published private(set) var showBottomLoader = false
        @Published var selectedFilter: TransactionFilter = .all
        @Published var searchText: String = ""
        @Published var dates: Set<DateComponents> = []

        var filters: IdentifiedArrayOf<TransactionFilter> { .init(uniqueElements: TransactionFilter.allCases) }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private var dateFrom: Date?
        private var dateTo: Date?
        private var listLoader: ListLoader?

        private let dateFormatter: DateTimeFormatter = .iso8601

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.permissionsService) private var permissionsService
        @Inject(\.transactionService) private var transactionService
        @Inject(\.transactionsLocalRepository) private var transactionsLocalRepository

        // MARK: - Init
        init() {
            setupBindings()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didPullRefresh() async {
            let refreshTask = Task { [weak self] in
                guard let self else { return }

                self.listLoader = .top
                defer { self.listLoader = nil }

                let searchData = self.createSearchData(
                    searchText: self.searchText,
                    selectedFilter: self.selectedFilter,
                    dateFrom: self.dateFrom,
                    dateTo: self.dateTo
                )
                await self.fetchData(searchData: searchData, refresh: true)
            }

            _ = await refreshTask.result
        }

        func didPullLoadNextPage() async {
            let pagination = appState.transactions.value.pagination
            guard pagination?.hasNextPage == true else { return }

            self.listLoader = .bottom
            defer { self.listLoader = nil }

            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = true
                }
            }

            let optionalText: String? = searchText.isEmpty ? nil : searchText
            let searchData = createSearchData(
                searchText: optionalText,
                selectedFilter: selectedFilter,
                dateFrom: dateFrom,
                dateTo: dateTo
            )
            await fetchData(searchData: searchData, refresh: false)

            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = false
                }
            }
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
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    // swiftlint:disable function_body_length
    func setupBindings() {
        appState.transactions.state
            .map(\.list)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                guard let self else { return }

                // handle loader
                let path = self.appState.navigation.value.path
                switch transactions {
                    case .notRequested, .requested:
                        break
                    case .isLoading:
                        // handle only if home screen at the top of navigation
                        guard path.last?.screen == .tabBar else { break }

                        if self.listLoader != nil { break }
                        self.appState.system[\.isLoading] = true
                    case .loaded, .failed:
                        // handle only if home screen at the top of navigation
                        guard path.last?.screen == .tabBar else { break }

                        self.appState.system[\.isLoading] = false
                }

                // handle datasource
                switch transactions {
                    case .requested(let lastValue):
                        self.transactions = .requested(lastValue: lastValue)
                    case .isLoading(let lastValue):
                        let lastValue = lastValue
                        self.transactions = .isLoading(lastValue: lastValue)
                    case .loaded(let value):
                        self.transactions = .loaded(value: value)
                    case .failed(let error):
                        appState.showError(message: error.localizedDescription)
                    default:
                        break
                }
            }
            .store(in: cancellable)
        $searchText
            .dropFirst(3)
            .removeDuplicates()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] text in
                guard let self else { return }

                log.debug("text: \(text)")

                Task {
                    self.appState.transactions[\.list] = .requested(lastValue: nil)
                    self.appState.system[\.isLoading] = true
                    defer { self.appState.system[\.isLoading] = false }

                    let searchData = self.createSearchData(
                        searchText: text,
                        selectedFilter: self.selectedFilter,
                        dateFrom: self.dateFrom,
                        dateTo: self.dateTo
                    )
                    await self.fetchData(searchData: searchData, refresh: true)
                }
            }
            .store(in: cancellable)

        $selectedFilter
            .scan((selectedFilter, selectedFilter)) { prev, current -> (Module.TransactionFilter, Module.TransactionFilter) in
                (prev.1, current)
            }
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] prev, current in
                guard
                    let self,
                    current != prev
                else { return }

                Task {
                    self.appState.transactions[\.list] = .requested(lastValue: nil)
                    self.appState.system[\.isLoading] = true
                    defer { self.appState.system[\.isLoading] = false }

                    let filter = current
                    let searchData = self.createSearchData(
                        searchText: self.searchText,
                        selectedFilter: filter,
                        dateFrom: self.dateFrom,
                        dateTo: self.dateTo
                    )
                    await self.fetchData(searchData: searchData, refresh: true)
                }
            }
            .store(in: cancellable)
        $dates
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] dates in
                guard let self else { return }

                let dates = dates
                    .map { Calendar.current.date(from: $0) }
                    .compactMap { $0 }
                let dateFrom = dates.min()
                let dateTo = dates.count > 1 ? dates.max() : nil

                Task {
                    self.appState.transactions[\.list] = .requested(lastValue: nil)
                    self.appState.system[\.isLoading] = true
                    defer { self.appState.system[\.isLoading] = false }

                    let searchData = self.createSearchData(
                        searchText: self.searchText,
                        selectedFilter: self.selectedFilter,
                        dateFrom: dateFrom,
                        dateTo: dateTo
                    )
                    await self.fetchData(searchData: searchData, refresh: true)

                    self.dateFrom = dateFrom
                    self.dateTo = dateTo
                }
            }
            .store(in: cancellable)
    }
    // swiftlint:enable function_body_length

    func startup() {
        Task { [weak self] in
            await self?.requestPermissions()
        }
    }

    // MARK: - Common
    func requestPermissions() async {
        await permissionsService.requestNotifications()
        await permissionsService.requestLocations(upTo: .authorizedAlways)
    }

    func createSearchData(
        searchText: String?,
        selectedFilter: Module.TransactionFilter,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) -> TransactionsService.TransactionsPagination.SearchData {
        let action: RequestModels.TransactionsList.Action?
        var stringDateFrom: String?
        var stringDateTo: String?

        switch selectedFilter {
            case .all:
                action = nil
            case .bought:
                action = .buy
            case .sold:
                action = .sell
        }

        if let dateFrom {
            stringDateFrom = self.dateFormatter.format(date: dateFrom)
        }
        if let dateTo {
            stringDateTo = self.dateFormatter.format(date: dateTo)
        }
        let searchData: TransactionsService.TransactionsPagination.SearchData = .init(
            search: searchText,
            createdAtFrom: stringDateFrom,
            createdAtTo: stringDateTo,
            action: action,
            buyerData: nil
        )

        return searchData
    }

    func fetchData(
        searchData: TransactionsService.TransactionsPagination.SearchData,
        refresh: Bool
    ) async {
        try? await transactionService.fetchTransactions(searchData: searchData, refresh: refresh)
    }
}
