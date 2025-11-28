//
//  CommoditiesListView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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

private typealias Module = CommoditiesListModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.CommoditiesList

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var isConfirmButtonEnabled: Bool {
            viewModel.selectedRow == .initialState ? false : true
        }

        private var selectedRow: Binding<CommodityGroupModel.Commodity?> {
            .init {
                viewModel.selectedRow
            } set: { newValue in
                if let newValue {
                    viewModel.selectedRow = newValue
                }
            }
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title, enableDivider: false)
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            list()
            bottomToolbar()
        }
    }

    @ViewBuilder func list() -> some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(viewModel.list) { item in
                    Module.RowView(row: item, selectedRow: selectedRow)
                }
            }
        }
    }

    @ViewBuilder func bottomToolbar() -> some View {
        AppButton(
            title: Localization.Buttons.confirm,
            isEnabled: isConfirmButtonEnabled,
            action: didTapConfirm
        )
        .padding(.top, 12)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background {
            AppColors.Other.white.colorSwiftUI
                .ignoresSafeArea()
        }
        .animation(.snappy, value: isConfirmButtonEnabled)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapConfirm() {
        viewModel.didTapConfirm()
    }
}

// MARK: - Previews
#if !RELEASE
struct CommoditiesListView_Previews: PreviewProvider {
    struct Container: View {
        @StateObject var viewModel: CommoditiesListModule.ViewModel = .init()

        var body: some View {
            CommoditiesListModule.MainView(viewModel: viewModel)
                .onAppear {
                    viewModel.list = .init(uniqueElements: [
                        .init(
                            id: "1",
                            name: "Cocoa",
                            commodities: [
                                .init(
                                    id: "1",
                                    code: "1801",
                                    name: "Cocoa beans, whole or broken, raw or roasted",
                                    unit: "",
                                    balance: nil,
                                    hasRecipe: true,
                                    group: .init(id: "1", name: "Cocoa")
                                ),
                                .init(
                                    id: "2",
                                    code: "1802",
                                    name: "Cocoa shells, husks, skins and other cocoa waste",
                                    unit: "",
                                    balance: nil,
                                    hasRecipe: true,
                                    group: .init(id: "1", name: "Cocoa")
                                )
                            ]
                        )
                    ])

                    viewModel.selectedRow = .init(
                        id: "2",
                        code: "1802",
                        name: "Cocoa shells, husks, skins and other cocoa waste",
                        unit: "",
                        balance: nil,
                        hasRecipe: true,
                        group: .init(id: "1", name: "Cocoa")
                    )
                }
        }
    }

    static var previews: some View {
        Container()
    }
}
#endif
