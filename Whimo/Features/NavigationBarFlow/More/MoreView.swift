//
//  MoreView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

private typealias Module = MoreModule
private typealias ModuleView = Module.MainView

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    // MARK: - Content
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            topPadding()
            list()
            Spacer()
                .frame(height: 16)
        }
        .overlay {
            header()
        }
    }

    // MARK: - Header
    @ViewBuilder func topPadding() -> some View {
        Spacer()
            .frame(height: 32)
    }

    @ViewBuilder func header() -> some View {
        VStack(spacing: .zero) {
            topPadding()
            DefaultDivider()
            Spacer()
        }
    }

    // MARK: - List
    @ViewBuilder func list() -> some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.list) { item in
                row(item)
            }
        }
    }

    // MARK: - Row Views
    @ViewBuilder func plainRow(_ item: Module.Row) -> some View {
        Module.RowView(row: item)
    }

    @ViewBuilder func labeledCell(_ item: Module.Row, detailsText: String) -> some View {
        LabeledContent {
            Text(detailsText)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                .padding(.horizontal, 16)
        } label: {
            Module.RowView(row: item)
        }
        .background {
            AppColors.Other.white.colorSwiftUI
                .ignoresSafeArea()
        }
    }

    @ViewBuilder func buttonRow(_ item: Module.Row) -> some View {
        Button {
            didTapRow(item)
        } label: {
            Module.RowView(row: item)
        }
    }

    @ViewBuilder func row(_ item: Module.Row) -> some View {
        VStack(spacing: .zero) {
            switch item {
                case .appVersion:
                    labeledCell(item, detailsText: "\(viewModel.appVersion) (\(viewModel.appBuild))")
                default:
                    buttonRow(item)
            }
            DefaultDivider()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapRow(_ row: Module.Row) {
        switch row {
            case .appVersion:
                break
            case .legalInformation:
                viewModel.didTapLegalInformation()
            case .logOut:
                viewModel.didTapLogout()
            case .deleteAccount:
                viewModel.didTapDeleteAccount()
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MoreModule.assemble()
        }
        .background {
            Color.red
        }
    }
}
#endif
