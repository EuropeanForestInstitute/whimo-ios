//
//  SettingsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
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

private typealias Module = SettingsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Settings

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
                    trailingItem: .more
                )
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
//                .localizableView()
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ScrollView {
            VStack(spacing: .zero) {
                if !viewModel.connectionReachable {
                    Module.OfflineInfoView()
                        .padding(16)
                }
                list()
            }
        }
    }

    @ViewBuilder func list() -> some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.list) { item in
                row(item)
            }
        }
    }

    @ViewBuilder func row(_ item: Module.Row) -> some View {
        VStack(spacing: .zero) {
            Button {
                didTapRow(item)
            } label: {
                Module.RowView(row: item)
            }
            if item.id != viewModel.list.last?.id {
                DefaultDivider()
            }
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapRow(_ row: Module.Row) {
        switch row {
            case .accountInfo:
                navigator.push(.accountInfo)
            case .changePassword:
                navigator.push(.changePassword)
            case .notifications:
                navigator.push(.notifications)
            case .language:
                navigator.push(.changeLanguageFullScreen)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsModule.assemble()
    }
}
#endif
