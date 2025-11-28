//
//  HomeView.swift
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

private typealias Module = HomeModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Home

// MARK: - MainView
extension Module {
    struct MainView: View {
        private enum Constants {
            static let datePickerButtonSize: CGFloat = 48
            static let datePickerYOffset: CGFloat = datePickerButtonSize + 24
        }

        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?
        @State private var showDatePicker: Bool = false

        private var dateFiltersEnabled: Bool { !viewModel.dates.isEmpty }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: Localization.title,
                    titlePrefferedFontStyle: .h2,
                    trailingItem: .notifications,
                    enableDivider: false
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
    // MARK: - Content
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            navigationToolbar()
                .padding(16)
            pagePicker()

            ZStack {
                ScrollView {
                    if viewModel.transactions.isEmpty {
                        emptyState()
                    } else if let datasource = viewModel.transactions.value {
                        VStack(spacing: .zero) {
                            list(datasource: datasource)
                            if viewModel.showBottomLoader {
                                bottomLoader()
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(.white.opacity(0.001))
                    }
                }
                .animation(.snappy, value: viewModel.transactions.value)
                .refreshable { await didPullRefresh() }
                .background(AppColors.Other.white.colorSwiftUI)
                if !viewModel.transactions.isEmpty {
                    addTransactionOverlayButton()
                }
            }
        }
    }

    // MARK: - Header
    @ViewBuilder func navigationToolbar() -> some View {
        HStack(spacing: 12) {
            AppTextField(
                placeholder: Localization.SerchField.placeholder,
                leadingAccessory: AppAssets.Home.searchIcon.imageSwiftUI,
                text: $viewModel.searchText,
                tapDestination: .textField(keyboardActiveField = .search)
            )
            .focused($keyboardActiveField, equals: .search)
            .submitLabel(.search)
            calendarPickerButton()
        }
    }

    @ViewBuilder func calendarPickerButton() -> some View {
        GeometryReader { proxy in
            let originY = proxy.frame(in: .global).origin.y + Constants.datePickerYOffset
            AppButton(
                leadingAccessory: AppAssets.Home.homeCalendarIcon.imageSwiftUI,
                style: .bordered,
                action: didtapShowdatePicker
            )
            .fullScreenCover(isPresented: $showDatePicker) {
                OverlayCalendarPicker(dates: $viewModel.dates, originY: originY)
                    .presentationBackground(.clear)
            }
        }
        .frame(
            width: Constants.datePickerButtonSize,
            height: Constants.datePickerButtonSize
        )
        .overlay {
            HStack {
                Spacer()
                VStack {
                    Circle()
                        .fill(AppColors.Primary.primarySeaBlue.colorSwiftUI)
                        .frame(width: 8, height: 8)
                        .opacity(dateFiltersEnabled ? 1 : 0)
                    Spacer()
                }
            }
            .frame(
                width: 52,
                height: 52
            )
            .animation(.snappy, value: dateFiltersEnabled)
        }
    }

    @ViewBuilder func pagePicker() -> some View {
        SegmentedPicker(
            items: viewModel.filters,
            selection: $viewModel.selectedFilter,
            title: { $0.title },
            icon: { $0.icon }
        )
    }

    // MARK: - List
    @ViewBuilder func list(datasource: IdentifiedArrayOf<TransactionModel>) -> some View {
        LazyVStack(spacing: .zero) {
            ForEach(datasource) { item in
                Button {
                    didTapDetails(item: item)
                } label: {
                    Module.RowView(model: item) { didTapAddMissignGeodata(item: item) }
                }
                .onAppear {
                    Task {
                        await didPullLoadNextPage(item.id == datasource.last?.id)
                    }
                }
                DefaultDivider()
            }
        }
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
                    AppAssets.Balance.balancePlusPlainIcon.imageSwiftUI
                    Text(Localization.Buttons.addTransaction)
                }
            })
            .applyProminentStyle()
            .frame(width: 200)
            Spacer()
        }
    }

    @ViewBuilder func bottomLoader() -> some View {
        ProgressView()
            .controlSize(.regular)
            .tint(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            .padding()
    }

    @ViewBuilder func addTransactionOverlayButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: didTapAddTransaction, label: {
                    AppAssets.Balance.balancePlusMediumIcon.imageSwiftUI
                })
                .applyProminentStyle()
                .frame(width: 48, height: 48)
                .padding(16)
            }
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapAddTransaction() {
        navigator.push(.createTransaction)
    }

    func didTapDetails(item: TransactionModel) {
        Task {
            await viewModel.didTapOpenDetails(item: item)
        }
    }

    func didPullRefresh() async {
        await viewModel.didPullRefresh()
    }

    func didPullLoadNextPage(_ condition: @autoclosure () -> Bool) async {
        guard condition() else { return }

        await viewModel.didPullLoadNextPage()
    }

    @MainActor
    func didtapShowdatePicker() {
        showDatePicker = true
    }

    func didTapAddMissignGeodata(item: TransactionModel) {
        let screen: Screen = .uploadFile(mode: .fileUploader(transactionId: item.id))
        navigator.push(screen)
    }
}

// MARK: - Previews
#if !RELEASE
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeModule.assemble()
    }
}
#endif
