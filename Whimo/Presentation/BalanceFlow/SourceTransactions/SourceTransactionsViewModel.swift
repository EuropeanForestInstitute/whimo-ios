//
//  SourceTransactionsViewModel.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 09.09.2026.
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

extension SourceTransactionsModule {
    @MainActor
    final class ViewModel: ObservableObject {
        let commodityId: String
        let seasonId: String
        @Published private(set) var rows: [TransactionModel]?
        @Published private(set) var nextPage: Int? = 1
        @Published private(set) var isLoading = false
        @Published private(set) var isCached = false
        @Published private(set) var error: TransactionHistoryError?
        private var generation = UUID()
        @Inject(\.commodityTransactionsInteractor) private var interactor
        @Inject(\.connectivity) private var connectivity
        @Inject(\.appState) private var appState

        init(commodityId: String, seasonId: String) {
            self.commodityId = commodityId
            self.seasonId = seasonId
        }

        func loadNextPage() async {
            guard !isLoading, error == nil, let page = nextPage else { return }

            let generation = self.generation
            isLoading = true
            defer { if self.generation == generation { isLoading = false } }
            do {
                let result = try await interactor.page(commodityId: commodityId, seasonId: seasonId, page: page,
                                                      cacheOnly: connectivity.isReachableValue == .notReachable)
                try Task.checkCancellation()
                guard self.generation == generation else { return }

                var combined = IdentifiedArrayOf<TransactionModel>(uniqueElements: rows ?? [])
                for item in result.list where combined[id: item.id]?.persistingData.state != .onDisk {
                    combined[id: item.id] = item
                }
                rows = TransactionListQuery.creationOrder(Array(combined))
                nextPage = result.nextPage
                isCached = isCached || result.isCached
            } catch {
                guard self.generation == generation, !(error is CancellationError), !Task.isCancelled else { return }

                self.error = (error as? TransactionHistoryError) ?? .loadFailed
            }
        }

        func retry() async {
            guard !isLoading else { return }

            error = nil
            await loadNextPage()
        }

        func cancelLoading() {
            generation = UUID()
            isLoading = false
        }

        func openTransaction(_ transaction: TransactionModel) {
            guard rows?.contains(where: { $0.id == transaction.id }) == true else { return }

            appState.navigation[\.path].append(.push(.transactionDetails(transactionId: transaction.id)))
        }
    }
}
