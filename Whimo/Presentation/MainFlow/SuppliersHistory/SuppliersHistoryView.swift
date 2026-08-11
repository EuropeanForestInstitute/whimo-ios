//
//  SuppliersHistoryView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.06.2025.
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
import UniformTypeIdentifiers

private typealias Module = SuppliersHistoryModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.SuppliersHistory

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var titleText: String {
            switch viewModel.supplierInfo.supplierType {
                case .mySupplier:
                    Localization.My.title
                case .other:
                    Localization.User.title(
                        "\(viewModel.supplierInfo.supplier.username.prefix(8))..."
                    )
            }
        }
        private var isMissingLocation: Bool {
            viewModel.supplierInfo.traceability?.isMissingLocation ?? false
        }
        private var isMySupplierState: Bool {
            guard case .mySupplier = viewModel.supplierInfo.supplierType else {
                return false
            }

            return true
        }
        private var navigationBarItem: NavBarModule.TrailingItem {
            .custom(
                image: AppAssets.TransactionDetails.transactionDetailsDownloadIcon.image,
                action: didTapDownloadZipAlert
            )
        }
//        private var navigationBarItemOptional: NavBarModule.TrailingItem? {
//            guard isMySupplierState else { return nil }
//
//            return navigationBarItem
//        }
        private var showExporter: Binding<Bool> {
            .init {
                switch viewModel.showExporter {
                    case .showZipExporter:
                        return true
                    default:
                        return false
                }
            } set: { newValue in
                if !newValue {
                    viewModel.showExporter = nil
                }
            }
        }
        private var exportedDocument: URLDocument? { viewModel.showExporter?.document }
        private var exportedContentType: UTType { viewModel.showExporter?.contentTypes.first ?? .plainText }
        private var exporterDefaultFilename: String { viewModel.showExporter?.defaultFilename ?? "" }

        // MARK: - Init
        init(supplierInfo: SupplierInfo) {
            _viewModel = .init(wrappedValue: .init(supplierInfo: supplierInfo))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: titleText,
                    trailingItem: navigationBarItem
                )
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
                .fileExporter(
                    isPresented: showExporter,
                    document: exportedDocument,
                    contentType: exportedContentType,
                    defaultFilename: exporterDefaultFilename
                ) { result in
                    switch result {
                        case .success(let success):
                            log.debug("success: \(success)")
                        case .failure(let error):
                            log.error("error: \(error)")
                    }
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            list()
            if isMySupplierState {
                mySupplierBottomOverlay()
            }
            if viewModel.supplierInfo.supplierType == .other {
                otherSuppliersBottomOverlay()
            }
        }
    }

    @ViewBuilder func list() -> some View {
        ScrollView {
            VStack(spacing: .zero) {
                Module.ListView(
                    items: viewModel.list,
                    didTapSupplyRow: didTapRow(_:),
                    onNextPageLoad: { didPullLoadNextPage($0()) }
                )
                if viewModel.showBottomLoader {
                    bottomLoader()
                }
            }
        }
    }

    @ViewBuilder func mySupplierBottomOverlay() -> some View {
        VStack(spacing: 12) {
            if isMissingLocation {
                AppButton(
                    title: Localization.BottomOverlay.My.requestLocation,
                    style: .prominent,
                    action: didTapRequestLocation
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder func otherSuppliersBottomOverlay() -> some View {
        HStack {
            Spacer()
            Button(action: didTapBackToRoot) {
                Text(Localization.BottomOverlay.Other.goBack)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
            .ignoresSafeArea()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Spacer()
        }
        .background {
            AppColors.Other.white.colorSwiftUI
                .ignoresSafeArea()
                .shadow(radius: 7, x: 0, y: 7)
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
    func didPullLoadNextPage(_ condition: Bool) {
        Task {
            guard condition else { return }

            await viewModel.didPullLoadNextPage()
        }
    }

    func didTapRow(_ item: SupplierTransactionModel) {
        viewModel.didTapSupplierRow(item)
    }

    func didTapBackToRoot() {
        viewModel.didTapBackToRoot()
    }

    func didTapDownloadZipAlert() {
        viewModel.showDowloadZipAlert()
    }

    func didTapRequestLocation() {
        viewModel.didTapRequestLocation()
    }
}

// MARK: - Previews
#if !RELEASE
struct SuppliersHistoryView_Previews: PreviewProvider {
    private static let previewItem: SuppliersHistoryModule.SupplierInfo? = .init(from: .init(
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
    ))

    static var previews: some View {
        if let previewItem {
            SuppliersHistoryModule.assemble(supplierInfo: previewItem)
        }
    }
}
#endif
