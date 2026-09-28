//
//  BalanceMainView.swift
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
import CommonUI
import Resources
import Utility

extension BalanceMainModule {
    struct MainView: View {
        @StateObject private var viewModel = ViewModel()
        @FocusState private var searchFocused: Bool
        @State private var availableHeight: CGFloat = 600

        var body: some View {
            VStack(spacing: 0) {
                toolbar
                if !viewModel.appliedFilter.isEmpty { filterChip }
                if viewModel.isCached {
                    Text(AppLocale.SeasonalBalance.cached).font(.footnote).padding(.horizontal, 16)
                }
                if viewModel.hasListError { errorState }
                ScrollView {
                    if let rows = viewModel.balances.value {
                        if rows.isEmpty {
                            EmptyStateView(
                                title: viewModel.hasCriteria ? AppLocale.SeasonalBalance.noMatches : AppLocale.Balance.EmptyState.title,
                                subtitle: viewModel.hasCriteria ? AppLocale.SeasonalBalance.adjustFilters : AppLocale.Balance.EmptyState.subtitle
                            ).padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(rows) { row in
                                    SeasonalBalanceRow(
                                        row: row, canConvert: viewModel.connectionReachable && !viewModel.isCached && row.season != nil,
                                        openDetails: { viewModel.openDetails(row) }, convert: { viewModel.convert(row) }
                                    )
                                    .onAppear {
                                        if row.id == rows.last?.id { Task { await viewModel.loadNextPage() } }
                                    }
                                    DefaultDivider()
                                }
                            }
                        }
                    }
                    if viewModel.balances.isLoading { ProgressView().padding() }
                }
                .frame(maxWidth: .infinity)
                .background(AppColors.Other.white.colorSwiftUI)
                .refreshable { await viewModel.didPullRefresh() }
            }
            .background(AppColors.Gray.gray5.colorSwiftUI)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { availableHeight = $0 }
            .applyNavigationBar(title: AppLocale.Balance.title, titlePrefferedFontStyle: .h2,
                                trailingItem: .notifications, enableDivider: false)
            .onDisappear { viewModel.filterSheet = nil }
            .sheet(item: $viewModel.filterSheet) { model in
                CommoditySeasonFilterSheet(viewModel: model, maximumHeight: availableHeight)
            }
        }

        private var toolbar: some View {
            HStack(spacing: 8) {
                AppTextField(text: $viewModel.searchText, backgroundColor: AppColors.Other.white.colorSwiftUI,
                             placeholder: AppLocale.SeasonalBalance.search,
                             leadingAccessory: AppAssets.Home.searchIcon.imageSwiftUI)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .accessibilityLabel(AppLocale.SeasonalBalance.search)
                AppButton(leadingAccessory: AppAssets.Home.homeFilterIcon.imageSwiftUI, style: .bordered) {
                    searchFocused = false
                    viewModel.openFilters()
                }
                .frame(width: 48, height: 48)
                .overlay(alignment: .topTrailing) {
                    if !viewModel.appliedFilter.isEmpty {
                        Circle().fill(AppColors.Primary.primarySeaBlue.colorSwiftUI).frame(width: 8, height: 8)
                    }
                }
                .accessibilityLabel(AppLocale.CommoditySeasonFilter.title)
                .accessibilityValue(viewModel.appliedFilter.title)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, viewModel.appliedFilter.isEmpty ? 16 : 0)
        }

        private var filterChip: some View {
            Button(action: viewModel.clearFilter) {
                HStack(spacing: 8) {
                    Text(chipTitle)
                        .font(FontBuilder.buildRegular(size: 14))
                        .foregroundStyle(AppColors.Primary.primaryBerryBlue.colorSwiftUI)
                    Image(systemName: "xmark").font(.system(size: 10))
                        .foregroundStyle(AppColors.Gray.gray50.colorSwiftUI)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(AppColors.Primary.primaryBirchWhite.colorSwiftUI, in: .rect(cornerRadius: 4))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocale.CommoditySeasonFilter.clear)
            .accessibilityValue(viewModel.appliedFilter.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }

        private var chipTitle: String {
            let filter = viewModel.appliedFilter
            guard let group = filter.group, let season = filter.season else { return filter.title }

            let prefix = group.name + " "
            let name = season.name.hasPrefix(prefix) ? String(season.name.dropFirst(prefix.count)) : season.name
            return group.name + ", " + name
        }

        private var errorState: some View {
            VStack {
                Text(AppLocale.SeasonalBalance.error)
                Button(AppLocale.CommoditySeasonFilter.retry) { Task { await viewModel.didPullRefresh() } }
            }
            .padding(.horizontal, 16)
        }
    }
}
