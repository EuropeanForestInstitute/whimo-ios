//
//  NotificationsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import typealias Utility.IdentifiedArrayOf

private typealias Module = NotificationsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Notifications

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english

        var datasource: IdentifiedArrayOf<RowData> {
            if viewModel.defaultOption.isEnabled {
                [viewModel.defaultOption] + viewModel.optionsList
            } else {
                [viewModel.defaultOption]
            }
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
        VStack {
            ScrollView {
                list(datasource: datasource)
            }
            AppButton(
                title: Localization.Buttons.save,
                isEnabled: viewModel.connectionReachable,
                action: didTapSave
            )
            .animation(.snappy, value: viewModel.connectionReachable)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder func list(datasource: IdentifiedArrayOf<Module.RowData>) -> some View {
        VStack(spacing: .zero) {
            ForEach(datasource) { item in
                VStack(spacing: .zero) {
                    Module.RowView(row: rowDataBinding(for: item))
                    if item.id != datasource.last?.id {
                        DefaultDivider()
                    }
                }
                .transformingTransition(opacity: 0, yOffset: -UIScreen.main.bounds.height)
            }
        }
        .animation(.snappy, value: viewModel.defaultOption)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    // MARK: - Setup
    func rowDataBinding(for item: Module.RowData) -> Binding<Module.RowData> {
        .init {
            item
        } set: { newValue in
            didTapToggle(item: newValue)
        }
    }

    // MARK: - Button Actions
    func didTapToggle(item: Module.RowData) {
        viewModel.didTapToggle(item: item)
    }

    func didTapSave() {
        Task { await viewModel.didTapSave() }
    }
}

// MARK: - Previews
#if !RELEASE
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsModule.assemble()
    }
}
#endif
