//
//  BalanceMainView.swift
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
import Resources

private typealias Module = BalanceMainModule
private typealias ModuleView = Module.MainView
private typealias Assets = AppAssets.Balance
private typealias Localization = AppLocale.Balance

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var singleGroup: CommodityGroupModel? {
            guard
                let datasource = viewModel.commodityGroups.value,
                datasource.count == 1 else { return nil }

            return datasource.first
        }

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack {
            if let singleGroup = singleGroup {
                BalanceGroupDetailsModule.assembleWithNavBarAttachments(
                    titleOverride: AppLocale.Balance.title,
                    model: singleGroup
                )
                .id(singleGroup.commodities.map({ $0.balance }))
                .animation(.snappy, value: singleGroup)
            } else {
                BalanceGroupsModule.assemble()
            }
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
struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceMainModule.assemble()
    }
}
#endif
