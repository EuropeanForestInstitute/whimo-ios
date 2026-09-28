//
//  BalanceDetailsView.swift
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

import SwiftUI
import CommonUI
import Resources

extension BalanceDetailsModule {
    struct MainView: View {
        @StateObject private var viewModel: ViewModel
        @State private var loadAttempt = 0
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english

        init(row: SeasonalBalance, isCached: Bool) {
            _viewModel = .init(wrappedValue: .init(row: row, isCached: isCached))
        }

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.showsCachedNotice {
                        Text(AppLocale.SeasonalBalance.cached)
                            .font(.footnote).padding(16)
                    }
                    summary
                    lastActivity
                    sourceTransactions
                    if viewModel.isLoading { ProgressView().padding(16) }
                    if viewModel.hasLoadError {
                        Button(AppLocale.CommoditySeasonFilter.retry) { loadAttempt += 1 }
                            .padding(16)
                    }
                }
            }
            .task(id: loadAttempt) { await viewModel.reload() }
            .refreshable { await viewModel.refresh() }
            .onDisappear { viewModel.cancelLoading() }
            .background(AppColors.Gray.gray5.colorSwiftUI)
            .applyNavigationBar(title: AppLocale.BalanceDetails.title, trailingItem: conversionItem)
        }

        private var conversionItem: NavBarModule.TrailingItem? {
            guard viewModel.row.hasRecipe else { return nil }

            return .custom(image: AppAssets.Balance.balanceConvertIcon.image
                            .withTintColor(AppColors.Gray.gray50.color, renderingMode: .alwaysOriginal),
                           accessibilityLabel: AppLocale.SeasonalBalance.convert(viewModel.row.commodity.name),
                           isEnabled: viewModel.canConvert, action: viewModel.convert)
        }

        private var summary: some View {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    title(AppLocale.TransactionDetails.Row.CommodityType.title)
                    description(viewModel.row.commodity.code + " " + viewModel.row.commodity.name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 12)
                DefaultDivider()
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        title(AppLocale.BalanceDetails.remainingBalance)
                        Spacer(minLength: 8)
                        description(quantity).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        title(AppLocale.BalanceDetails.remainingBalance)
                        description(quantity)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                DefaultDivider()
                Button(action: viewModel.showHarvestSeasonInfo) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            title(AppLocale.HarvestSeasonPicker.Season.title)
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 8) { seasonValue }
                                VStack(alignment: .leading, spacing: 8) { seasonValue }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        chevron
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocale.HarvestSeasonPicker.Season.title)
                .accessibilityValue(TransactionSeasonPresentation(season: viewModel.row.season).accessibilityLabel)
                DefaultDivider()
                Button(action: viewModel.showTraceabilityInfo) {
                    HStack(spacing: 8) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                title(AppLocale.TransactionDetails.Row.TraceabilityStatus.title)
                                Spacer(minLength: 8)
                                traceabilityValue.fixedSize()
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                title(AppLocale.TransactionDetails.Row.TraceabilityStatus.title)
                                traceabilityValue
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        chevron
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                DefaultDivider()
            }
            .background(AppColors.Other.white.colorSwiftUI)
        }

        private var lastActivity: some View {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    title(AppLocale.BalanceDetails.lastActivity)
                    Spacer(minLength: 8)
                    description(activityDate).fixedSize()
                }
                VStack(alignment: .leading, spacing: 8) {
                    title(AppLocale.BalanceDetails.lastActivity)
                    description(activityDate)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppColors.Other.white.colorSwiftUI)
        }

        private var activityDate: String {
            guard let date = viewModel.history?.first?.creationDate else { return "—" }

            return DateTimeFormatter.transaction(locale: currentLocalize.locale).string(from: date)
        }

        private var sourceTransactions: some View {
            VStack(spacing: 0) {
                Button(action: viewModel.openSourceTransactions) {
                    HStack(spacing: 8) {
                        Text(AppLocale.BalanceDetails.sourceTransactions)
                            .appFontMediumSize18()
                            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        chevron
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canOpenSourceTransactions)
                .accessibilityAddTraits(.isHeader)
                if viewModel.historyIsCached {
                    Text(AppLocale.CommoditySeasonFilter.cachedTransactions)
                        .font(.footnote).padding(16)
                }
                if let history = viewModel.history {
                    if history.isEmpty {
                        Text(AppLocale.Home.EmptyState.title)
                            .appFontRegularSize16().padding(24)
                    } else {
                        ForEach(history) { transaction in
                            VStack(spacing: 0) {
                                Button { viewModel.openTransaction(transaction) } label: {
                                    TransactionRow(model: transaction) { viewModel.openTransaction(transaction) }
                                }
                                .buttonStyle(.plain)
                                DefaultDivider()
                            }
                        }
                    }
                }
                if viewModel.isHistoryLoading { ProgressView().padding(16) }
                if let error = viewModel.historyError {
                    VStack(spacing: 12) {
                        Text(historyMessage(error)).appFontRegularSize14()
                            .multilineTextAlignment(.center)
                        if error != .invalidQuery {
                            Button(AppLocale.CommoditySeasonFilter.retry) { loadAttempt += 1 }
                        }
                    }.padding(16)
                }
            }
        }

        private func historyMessage(_ error: TransactionHistoryError) -> String {
            switch error {
                case .invalidQuery: AppLocale.TransactionSeason.unavailable
                case .unavailableCache: AppLocale.BalanceDetails.historyConnectionRequired
                case .incompleteResponse, .loadFailed: AppLocale.BalanceDetails.historyError
            }
        }

        private var quantity: String {
            DecimalFormatter.default.format(value: String(viewModel.row.volume)) + viewModel.row.commodity.unit
        }

        @ViewBuilder private var seasonValue: some View {
            let presentation = TransactionSeasonPresentation(season: viewModel.row.season)
            description(presentation.title)
            if let status = presentation.status {
                Text(status.title)
                    .font(FontBuilder.buildMedium(size: 12))
                    .foregroundStyle(status.foregroundColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(status.backgroundColor, in: .rect(cornerRadius: 3))
            }
        }

        @ViewBuilder private var traceabilityValue: some View {
            if let traceability = viewModel.row.traceability {
                Text(traceability.fullTitle)
                    .appFontMediumSize14()
                    .foregroundStyle(traceability.primaryColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(traceability.secondaryColor, in: .rect(cornerRadius: 4))
            } else {
                description("—")
            }
        }

        private var chevron: some View {
            AppAssets.Shared.sharedChevronRight.imageSwiftUI
                .frame(width: 20, height: 20).accessibilityHidden(true)
        }

        private func title(_ text: String) -> some View {
            Text(text).appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }

        private func description(_ text: String) -> some View {
            Text(text).appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
