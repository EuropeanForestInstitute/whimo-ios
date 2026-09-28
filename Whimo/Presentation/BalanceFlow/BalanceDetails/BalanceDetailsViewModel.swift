//
//  BalanceDetailsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 14.08.2025.
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

import Foundation
import Combine
import CommonUI
import Resources
import Utility

extension BalanceDetailsModule {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published private(set) var row: SeasonalBalance
        @Published private(set) var isCached: Bool
        @Published private(set) var connectionReachable: Bool
        @Published private(set) var isLoading = false
        @Published private(set) var hasLoadError = false
        private var hasLoaded = false
        private var balanceGeneration = UUID()
        private var refreshGeneration = UUID()
        private var isRefreshing = false
        @Published private(set) var history: [TransactionModel]?
        @Published private(set) var historyIsCached = false
        @Published private(set) var isHistoryLoading = false
        @Published private(set) var historyError: TransactionHistoryError?
        private var historyGeneration = UUID()
        var lastActivity: String? { history?.first?.createdAt }

        @Inject(\.commodityTransactionsInteractor) private var historyInteractor

        @Inject(\.appState) private var appState
        @Inject(\.balanceListInteractor) private var interactor
        @Inject(\.connectivity) private var connectivity
        @Inject(\.alertManager) private var alertManager
        private let cancellable = CancelBag()

        var canConvert: Bool { row.hasRecipe && row.season != nil && !isCached && connectionReachable }
        var showsCachedNotice: Bool { isCached || !connectionReachable }

        init(row: SeasonalBalance, isCached: Bool) {
            self.row = row
            self.isCached = isCached
            self.connectionReachable = true
            connectionReachable = connectivity.isReachableValue != .notReachable
            connectivity.isReachable.receive(on: DispatchQueue.main)
                .sink { [weak self] status in self?.connectionReachable = status != .notReachable }
                .store(in: cancellable)
        }

        func reload() async {
            guard !Task.isCancelled else { return }

            cancelLoading()
            await refresh()
        }

        func refresh() async {
            guard !isRefreshing, !Task.isCancelled else { return }

            let generation = UUID()
            refreshGeneration = generation
            isRefreshing = true
            defer { if refreshGeneration == generation { isRefreshing = false } }
            async let balance: Void = refreshBalance(generation: generation)
            async let transactions: Void = refreshHistory(generation: generation)
            _ = await (balance, transactions)
        }

        func cancelLoading() {
            refreshGeneration = UUID()
            balanceGeneration = UUID()
            historyGeneration = UUID()
            isRefreshing = false
            isLoading = false
            isHistoryLoading = false
        }

        private func refreshBalance(generation: UUID) async {
            guard refreshGeneration == generation else { return }

            await load(refresh: true)
        }

        private func refreshHistory(generation: UUID) async {
            guard refreshGeneration == generation else { return }

            await loadHistory()
        }

        func load(refresh: Bool = false) async {
            guard !Task.isCancelled, !isLoading, refresh || !hasLoaded, let season = row.season else { return }

            let generation = UUID()
            balanceGeneration = generation
            isLoading = true
            hasLoadError = false
            defer { if balanceGeneration == generation { isLoading = false } }
            do {
                let result = try await interactor.exact(commodityId: row.commodity.id, seasonId: season.id)
                try Task.checkCancellation()
                guard balanceGeneration == generation else { return }

                row = .init(id: row.id, volume: result.volume, commodity: row.commodity,
                            season: row.season, traceability: result.traceability, hasRecipe: row.hasRecipe)
                isCached = result.isCached
                hasLoaded = true
            } catch {
                guard balanceGeneration == generation, !(error is CancellationError), !Task.isCancelled else { return }

                hasLoadError = true
                await appState.showError(message: AppLocale.SeasonalBalance.error)
            }
        }

        func loadHistory() async {
            guard !Task.isCancelled else { return }
            guard let season = row.season, !season.id.isEmpty, !row.commodity.id.isEmpty else {
                historyError = .invalidQuery
                return
            }
            let generation = UUID()
            historyGeneration = generation
            isHistoryLoading = true
            historyError = nil
            defer { if historyGeneration == generation { isHistoryLoading = false } }
            do {
                let result = try await historyInteractor.recent(
                    commodityId: row.commodity.id, seasonId: season.id,
                    cacheOnly: connectivity.isReachableValue == .notReachable
                )
                try Task.checkCancellation()
                guard historyGeneration == generation else { return }

                history = Array(result.list)
                historyIsCached = result.isCached
            } catch {
                guard historyGeneration == generation, !(error is CancellationError), !Task.isCancelled else { return }

                historyError = (error as? TransactionHistoryError) ?? .loadFailed
            }
        }

        var canOpenSourceTransactions: Bool {
            !row.commodity.id.isEmpty && row.season?.id.isEmpty == false
        }

        func openSourceTransactions() {
            guard canOpenSourceTransactions, let season = row.season else { return }

            appState.navigation[\.path].append(.push(.sourceTransactions(commodityId: row.commodity.id, seasonId: season.id)))
        }

        func openTransaction(_ transaction: TransactionModel) {
            guard history?.contains(where: { $0.id == transaction.id }) == true else { return }

            appState.navigation[\.path].append(.push(.transactionDetails(transactionId: transaction.id)))
        }

        func convert() {
            guard canConvert, connectivity.isReachableValue != .notReachable, let season = row.season else { return }

            appState.navigation[\.path].append(.push(.convertCommodityList(commodity: row.conversionCommodity, season: season)))
        }

        func showHarvestSeasonInfo() {
            alertManager.show(.init(
                title: AppLocale.HarvestSeasonPicker.Season.title,
                contentView: .init(HarvestSeasonInfoPopup(season: row.season))
            ))
        }

        func showTraceabilityInfo() {
            typealias Localization = AppLocale.TransactionDetails.Popups.TraceabilityStatus
            alertManager.show(.init(
                title: Localization.title,
                subtitle: Localization.description,
                contentView: .init(TraceabilityStatusInfoPopup())
            ))
        }
    }
}
