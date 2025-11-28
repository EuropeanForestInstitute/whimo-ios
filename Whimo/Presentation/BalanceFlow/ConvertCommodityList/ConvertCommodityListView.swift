//
//  ConvertCommodityListView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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

private typealias Module = ConvertCommodityListModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.ConvertCommodityList

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Init
        init(commodity: CommodityGroupModel.Commodity) {
            self._viewModel = .init(wrappedValue: .init(commodity: commodity))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
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
        VStack(spacing: 16) {
            subtitle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            ScrollView {
                VStack(spacing: .zero) {
                    Module.ListView(
                        items: viewModel.items,
                        didTapItem: didTapItem(model:),
                        onNextPageLoad: { didPullLoadNextPage($0()) }
                    )
                    if viewModel.showBottomLoader {
                        bottomLoader()
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder func subtitle() -> some View {
        Text(Localization.subtitle)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }

    @ViewBuilder func bottomLoader() -> some View {
        ProgressView()
            .controlSize(.regular)
            .tint(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            .padding()
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapItem(model: ConversionRuleModel) {
        viewModel.didTapOpenConverterDetails(model: model)
    }

    func didPullLoadNextPage(_ condition: Bool) {
        Task {
            guard condition else { return }

            await viewModel.didPullLoadNextPage()
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityListView_Previews: PreviewProvider {
    private static let commodity: CommodityGroupModel.Commodity = .init(
        id: "1",
        code: "1234",
        name: "Coffee",
        unit: "kg",
        balance: 123.45,
        hasRecipe: true,
        group: .init(id: "1", name: "Coffee Group")
    )

    static var previews: some View {
        ConvertCommodityListModule.assemble(commodity: commodity)
    }
}
#endif
