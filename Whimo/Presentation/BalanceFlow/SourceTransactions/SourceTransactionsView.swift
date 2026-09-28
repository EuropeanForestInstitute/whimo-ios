//
//  SourceTransactionsView.swift
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

import SwiftUI
import CommonUI
import Resources

extension SourceTransactionsModule {
    struct MainView: View {
        @StateObject private var viewModel: ViewModel
        @State private var retryTask: Task<Void, Never>?

        init(commodityId: String, seasonId: String) {
            _viewModel = .init(wrappedValue: .init(commodityId: commodityId, seasonId: seasonId))
        }

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isCached {
                        Text(AppLocale.CommoditySeasonFilter.cachedTransactions)
                            .font(.footnote).padding(16)
                    }
                    if let rows = viewModel.rows {
                        if rows.isEmpty {
                            Text(AppLocale.Home.EmptyState.title)
                                .appFontRegularSize16().padding(24)
                        }
                        ForEach(rows) { transaction in
                            VStack(spacing: 0) {
                                Button { viewModel.openTransaction(transaction) } label: {
                                    TransactionRow(model: transaction) { viewModel.openTransaction(transaction) }
                                }
                                .buttonStyle(.plain)
                                DefaultDivider()
                            }
                        }
                    }
                    if let error = viewModel.error {
                        VStack(spacing: 12) {
                            Text(message(error)).appFontRegularSize14()
                                .multilineTextAlignment(.center)
                            if error != .invalidQuery {
                                Button(AppLocale.CommoditySeasonFilter.retry) {
                                    retryTask = Task { await viewModel.retry() }
                                }.disabled(viewModel.isLoading)
                            }
                        }.padding(16)
                    } else if viewModel.nextPage != nil {
                        ProgressView().padding(16)
                            .task(id: viewModel.nextPage) { await viewModel.loadNextPage() }
                    }
                }
            }
            .onDisappear {
                retryTask?.cancel()
                viewModel.cancelLoading()
            }
            .background(AppColors.Other.white.colorSwiftUI)
            .applyNavigationBar(title: AppLocale.BalanceDetails.sourceTransactions)
        }

        private func message(_ error: TransactionHistoryError) -> String {
            switch error {
                case .invalidQuery: AppLocale.TransactionSeason.unavailable
                case .unavailableCache: AppLocale.BalanceDetails.historyConnectionRequired
                case .incompleteResponse, .loadFailed: AppLocale.BalanceDetails.historyError
            }
        }
    }
}
