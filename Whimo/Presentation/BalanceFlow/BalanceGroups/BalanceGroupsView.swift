//
//  BalanceGroupsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.08.2025.
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

private typealias Module = BalanceGroupsModule
private typealias ModuleView = Module.MainView
private typealias Assets = AppAssets.Balance
private typealias Localization = AppLocale.Balance

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: Localization.title,
                    titlePrefferedFontStyle: .h2,
                    trailingItem: .notifications
                )
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack {
            if viewModel.commodityGroups.isEmpty {
                emptyState()
            } else if let datasource = viewModel.commodityGroups.value {
                Module.GroupsList(
                    list: datasource,
                    didTapCommodityGroup: didTapCommodityGroup
                )
            } else {
                Rectangle()
                    .fill(.white.opacity(0.001))
            }
        }
        .animation(.snappy, value: viewModel.commodityGroups.value)
        .refreshable { await didPullRefresh() }
    }

    @ViewBuilder func emptyState() -> some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 80)
            EmptyStateView(
                title: Localization.EmptyState.title,
                subtitle: Localization.EmptyState.subtitle
            )
            Button(action: didTapAddTransaction, label: {
                HStack {
                    Assets.balancePlusPlainIcon.imageSwiftUI
                    Text(Localization.addTx)
                }
            })
            .applyProminentStyle()
            .frame(width: 200)
            Spacer()
        }
        .background {
            AppColors.Other.white.colorSwiftUI
                .ignoresSafeArea()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didPullRefresh() async {
        await viewModel.didPullRefresh()
    }

    func didTapAddTransaction() {
        navigator.push(.createTransaction)
    }

    func didTapCommodityGroup(_ model: CommodityGroupModel) {
        navigator.push(.groupBalanceDetails(commodityGroup: model))
    }
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceGroupsModule.assemble()
    }
}
#endif
