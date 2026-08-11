//
//  AccountInfoView.swift
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

private typealias Module = AccountInfoModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.AccountInfo

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ScrollView {
            VStack {
                if viewModel.userProfile != .empty {
                    profileList()
                    Spacer()
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.001))
                }
            }
            .animation(.snappy, value: viewModel.userProfile)
        }
        .refreshable { await didPullRefresh() }
    }

    @ViewBuilder func profileList() -> some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.rows) { row in
                switch row {
                    case .userID:
                        profileRow(row)
                    case .email:
                        actionProfileRow(row)
                    case .phone:
                        actionProfileRow(row)
                }
                DefaultDivider()
            }
        }
    }

    @ViewBuilder func profileRow(_ rowType: Module.Row) -> some View {
        Module.RowView(
            row: rowType,
            onCopyDidTap: viewModel.didTapCopy
        )
    }

    @ViewBuilder func actionProfileRow(_ rowType: Module.Row) -> some View {
        Button {
            didTapProfileRow(rowType)
        } label: {
            Module.RowView(
                row: rowType,
                onCopyDidTap: viewModel.didTapCopy
            )
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapProfileRow(_ rowType: Module.Row) {
        viewModel.didTapProfileRow(rowType)
    }

    func didPullRefresh() async {
        await viewModel.didPullRefresh()
    }
}

// MARK: - Previews
#if !RELEASE
struct AccountInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoModule.assemble()
    }
}
#endif
