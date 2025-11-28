//
//  NotificationsListView.swift
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
import Utility

private typealias Module = NotificationsListModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.NotificationsList

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
            picker()
            if viewModel.notifications.isEmpty {
                emptyState()
            } else if let notifications = viewModel.notifications.value {
                list(datasource: notifications)
            } else {
                Spacer()
            }
        }
    }

    @ViewBuilder func picker() -> some View {
        SegmentedPicker(
            items: viewModel.filters,
            selection: $viewModel.selectedFilter,
            title: { $0.title }
        )
    }

    @ViewBuilder func list(datasource: IdentifiedArrayOf<Notifications.Model>) -> some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(datasource) { item in
                    Module.RowView(model: item) {
                        didTapOpenDetails(item: item)
                    }
                    .onAppear {
                        Task {
                            await didPullLoadNextPage(item.id == datasource.last?.id)
                        }
                    }
                    DefaultDivider()
                }
                if viewModel.showBottomLoader {
                    bottomLoader()
                }
            }
        }
        .animation(.snappy, value: viewModel.notifications.value)
        .refreshable { await didPullRefresh() }
    }

    @ViewBuilder func emptyState() -> some View {
        VStack {
            Spacer()
                .frame(height: 80)
            EmptyStateView(
                title: Localization.EmptyState.title,
                subtitle: Localization.EmptyState.subtitle
            )
            Spacer()
        }
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
    func didPullRefresh() async {
        await viewModel.didPullRefresh()
    }

    func didPullLoadNextPage(_ condition: @autoclosure () -> Bool) async {
        guard condition() else { return }

        await viewModel.didPullLoadNextPage()
    }

    func didTapOpenDetails(item: Notifications.Model) {
        viewModel.didTapOpenDetails(item: item)
    }
}

// MARK: - Previews
#if !RELEASE
struct NotificationsListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsListModule.assemble()
    }
}
#endif
