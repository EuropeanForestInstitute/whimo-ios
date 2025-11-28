//
//  TransactionDetailsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.05.2025.
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

private typealias Module = TransactionDetailsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.TransactionDetails
private typealias Assets = AppAssets.TransactionDetails

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var navigationBarItem: NavBarModule.TrailingItem {
            .custom(
                image: Assets.transactionDetailsDownloadIcon.image,
                action: didTapDownload
            )
        }
        private var navigationBarItemOptional: NavBarModule.TrailingItem? {
            viewModel.transaction.value?.status == .accepted ? navigationBarItem : nil
        }

        // MARK: - Init
        init(transactionId: String) {
            _viewModel = .init(wrappedValue: .init(transactionId: transactionId))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: Localization.title,
                    trailingItem: navigationBarItemOptional
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
            list()
            actionButtons()
        }
    }

    @ViewBuilder func actionButtons() -> some View {
        if viewModel.transactionState == .sync {
            animatedBottomOverlay(value: viewModel.waitingCreatorResponse) {
                creatorButtonsView()
            }
            animatedBottomOverlay(value: viewModel.waitingRecipientResponse) {
                recipientButtonsView()
            }
        }
    }

    // MARK: - List
    @ViewBuilder func list() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                if let transaction = viewModel.transaction.value {
                    Module.ListView(
                        rows: viewModel.rows,
                        transaction: transaction,
                        pieChartData: viewModel.pieChartData.value,
                        didTapAddMissignGeodata: didTapAddMissignGeodata,
                        didTapTraceabilityStatus: didTapTraceabilityStatus,
                        didTapShowRecipientInfo: didTapShowRecipientInfo,
                        didTapTransactionStatus: didTapTransactionStatus
                    )
                    .animation(.snappy, value: viewModel.pieChartData.value)
                    VStack {
                        if transaction.action == .buy,
                           let supplierTransactions = viewModel.supplierTransactions.value,
                           !supplierTransactions.isEmpty {
                            Module.SuppliersHistoryList(
                                items: .init(uniqueElements: supplierTransactions.prefix(2)),
                                didTapViewAll: didTapShowSupplierHistory,
                                didTapSupplyRow: didTapSupplyRow(_:)
                            )
                        } else {
                            EmptyView()
                        }
                    }
                    .animation(.snappy, value: viewModel.supplierTransactions.value)
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.001))
                }
            }
            .animation(.snappy, value: viewModel.transaction.value)
        }
    }

    // MARK: - Bottom Overlays
    @ViewBuilder func bottomOverlay<Content: View>(_ content: () -> Content) -> some View {
        content()
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background {
                AppColors.Other.white.colorSwiftUI
                    .ignoresSafeArea()
                    .shadow(radius: 7, x: 0, y: 7)
            }
    }

    @ViewBuilder func animatedBottomOverlay<Content: View>(
        value: @autoclosure () -> Bool,
        _ content: () -> Content
    ) -> some View {
        let _value = value()
        VStack {
            if _value {
                bottomOverlay { content() }
            } else {
                EmptyView()
            }
        }
        .animation(.snappy, value: _value)
    }

    @ViewBuilder func recipientButtonsView() -> some View {
        VStack(spacing: 12) {
            AppButton(
                title: Localization.ForMe.Buttons.reject,
                style: .bordered,
                action: didTapRejectTransaction
            )
            AppButton(
                title: Localization.ForMe.Buttons.accept,
                action: didTapAcceptTransaction
            )
        }
    }

    @ViewBuilder func creatorButtonsView() -> some View {
        VStack(spacing: 12) {
            AppButton(
                title: Localization.FromMe.Buttons.cancel,
                style: .bordered,
                action: didTapRejectTransaction
            )
            AppButton(
                title: Localization.FromMe.Buttons.resendNotification,
                action: didTapResendNotification
            )
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    // MARK: - Actions
    func didTapTraceabilityStatus() {
        viewModel.showTraceabilityInfo()
    }

    func didTapShowRecipientInfo() {
        viewModel.showRecipientInfo()
    }

    func didTapTransactionStatus() {
        viewModel.showTransactionInfo()
    }

    func didTapShowSupplierHistory() {
        viewModel.didTapShowSupplierHistory()
    }

    func didTapSupplyRow(_ item: SupplierTransactionModel) {
        viewModel.didTapSupplyRow(item)
    }

    func didTapAddMissignGeodata() {
        viewModel.didTapAddMissignGeodata()
    }

    func didTapDownload() {
        viewModel.didTapOpenDowloadView()
    }

    func didTapRejectTransaction() {
        Task { await viewModel.didTapRejectTransaction() }
    }

    func didTapAcceptTransaction() {
        Task { await viewModel.didTapAcceptTransaction() }
    }

    func didTapResendNotification() {
        Task { await viewModel.didTapResendNotification() }
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsView_Previews: PreviewProvider {
    private static var transaction: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
        volume: 5.0,
        isBuyingFromFarmer: false,
        commodity: .init(
            id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
            code: "3298",
            name: "Roasted beans",
            unit: "buckets",
            balance: nil,
            hasRecipe: false,
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: .init(
            id: "id1",
            username: "username1",
            gadgets: []
        ),
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1",
        persistingData: .sync()
    )
    private static var transaction2: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: "2025-07-10T23:15:42.205456Z",
        updatedAt: nil,
        type: .producer,
        status: .pending,
        action: .buy,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
        volume: 5.0,
        isBuyingFromFarmer: false,
        commodity: .init(
            id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
            code: "3298",
            name: "Roasted beans",
            unit: "buckets",
            balance: nil,
            hasRecipe: false,
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: .init(
            id: "id1",
            username: "username1",
            gadgets: []
        ),
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1",
        persistingData: .sync()
    )
    private static var transaction3: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: "2025-07-10T23:15:42.205456Z",
        updatedAt: nil,
        type: .producer,
        status: .pending,
        action: .sell,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
        volume: 5.0,
        isBuyingFromFarmer: false,
        commodity: .init(
            id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
            code: "3298",
            name: "Roasted beans",
            unit: "buckets",
            balance: nil,
            hasRecipe: false,
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: .init(
            id: "id1",
            username: "username1",
            gadgets: []
        ),
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1",
        persistingData: .sync()
    )

    static var previews: some View {
        TransactionDetailsModule.assemble(transactionId: transaction.id)
        TransactionDetailsModule.assemble(transactionId: transaction2.id)
        TransactionDetailsModule.assemble(transactionId: transaction3.id)
    }
}
#endif
