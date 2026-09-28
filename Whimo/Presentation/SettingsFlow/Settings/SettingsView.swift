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
import Utility

private typealias Module = SettingsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Settings

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject private var viewModel: ViewModel = .init()
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
                testModeToggle()
                list()
                if viewModel.isTestMode {
                    NoteBanner(text: AppLocale.TestMode.settingsUnavailable, state: .info)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                }
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
                Module.RowView(row: item, isEnabled: viewModel.isRowEnabled(item))
            }
            .disabled(!viewModel.isRowEnabled(item))
            if item.id != viewModel.list.last?.id {
                DefaultDivider()
            }
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapRow(_ row: Module.Row) {
        guard viewModel.isRowEnabled(row) else { return }

        switch row {
            case .accountInfo:
                navigator.push(.accountInfo)
            case .changePassword:
                navigator.push(.changePassword)
            case .notifications:
                navigator.push(.notifications)
            case .language:
                navigator.push(.changeLanguageFullScreen)
            case .feedback:
                Task { await viewModel.sendFeedbackEmail() }
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

private extension SettingsModule.MainView {
    func testModeToggle() -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppLocale.TestMode.title).appFontMediumSize16()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                Text(AppLocale.TestMode.subtitle).appFontRegularSize12()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(AppLocale.TestMode.title, isOn: Binding(get: { viewModel.isTestMode }, set: { enabled in
                Task { await viewModel.setTestModeEnabled(enabled) }
            }))
            .labelsHidden()
            .accessibilityHint(AppLocale.TestMode.subtitle)
            .scaleEffect(0.85, anchor: .topTrailing)
            .frame(width: 44, height: 24)
        }
        .tint(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        .disabled(viewModel.isSwitchingMode)
        .padding(16)
        .background(AppColors.Other.white.colorSwiftUI)
    }
}

extension SettingsModule {
    struct EntryContent: View {
        let isBlocked: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                NoteBanner(text: isBlocked ? AppLocale.TestMode.unsynced : AppLocale.TestMode.explanation,
                    state: isBlocked ? .warning : .info)
                    .fixedSize(horizontal: false, vertical: true)
                if isBlocked {
                    Text(AppLocale.TestMode.syncRequired)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                } else {
                    ForEach([AppLocale.TestMode.create, AppLocale.TestMode.explore, AppLocale.TestMode.learn,
                             AppLocale.TestMode.separate, AppLocale.TestMode.returnToLive], id: \.self) { text in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
                            Text(text)
                        }
                    }
                }
            }
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .padding(16)
        }
    }
}
