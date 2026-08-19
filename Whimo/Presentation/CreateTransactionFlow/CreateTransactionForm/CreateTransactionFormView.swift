//
//  CreateTransactionFormView.swift
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
import CoreLocation

private typealias Module = CreateTransactionFormModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.CreateTransactionForm

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var titleText: String {
            switch viewModel.transactionType {
                case .producer:
                    Localization.titleProducer
                case .downstream:
                    Localization.titleDownstream
            }
        }

        private var commodityText: String? {
            guard viewModel.commodityType != .initialState else {
                return nil
            }

            return "\(viewModel.commodityType.code) \(viewModel.commodityType.name)"
        }

        private var volumeText: String? {
            viewModel.volumeAmount.isEmpty
            ? nil
            : "\(viewModel.volumeAmount) \(viewModel.commodityType.unit)"
        }

        private var inviteRecipientText: String? {
            switch viewModel.transactionType {
                case .producer(let seller):
                    switch seller {
                        case .farmer:
                            return nil
                        case .cooperative(recipient: let recipient):
                            return recipient?.recipientContact
                    }
                case .downstream:
                    return nil
            }
        }

        private var recipientText: String? {
            switch viewModel.transactionType {
                case .producer:
                    return nil
                case .downstream(_, let recipient):
                    if !recipient.recipientID.isEmpty {
                        return "#\(recipient.recipientID)"
                    } else if !recipient.email.isEmpty {
                        return recipient.email
                    } else if !recipient.phone.isEmpty {
                        return recipient.phone
                    }

                    return nil
            }
        }

        // MARK: - Init
        init(transactionType: TransactionType) {
            self._viewModel = .init(wrappedValue: .init(transactionType: transactionType))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: titleText)
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
        VStack(spacing: 16) {
            NoteBanner(text: Localization.Note.title)
                .padding(.top, 16)
                .padding(.horizontal, 16)
            list()
            Spacer()
            AppButton(
                title: Localization.Buttons.save,
                isEnabled: viewModel.isSaveButtonEnabled,
                action: didTapSave
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .animation(.snappy, value: viewModel.isSaveButtonEnabled)
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
        Button {
            didTapRow(item)
        } label: {
            switch item {
                case .geodata:
                    Module.RowView(row: item) {
                        VStack {
                            if let file = viewModel.farmLocation?.selectedFile {
                                Module.FileRowView(file: file)
                            } else {
                                Module.DescriptionText(
                                    row: item,
                                    value: viewModel.farmLocation?.coordinates.formatToDMS()
                                )
                            }
                        }
                    }
                case .commodity:
                    Module.RowView(row: item) {
                        Module.DescriptionText(row: item, value: commodityText)
                    }
                case .volume:
                    Module.RowView(row: item) {
                        Module.DescriptionText(row: item, value: volumeText)
                    }
                case .inviteSupplier:
                    Module.RowView(row: item) {
                        Module.DescriptionText(row: item, value: inviteRecipientText)
                    }
                case .supplier, .buyer:
                    Module.RowView(row: item) {
                        Module.DescriptionText(row: item, value: recipientText)
                    }
            }
        }
        if item.id != viewModel.list.last?.id {
            DefaultDivider()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapRow(_ row: Module.Row) {
        switch row {
            case .geodata:
                viewModel.didTapChooseFarmGeodataScreen()
            case .commodity:
                navigator.push(.commoditiesList)
            case .volume:
                viewModel.didTapOpenCommodityVolumeScreen()
            case .inviteSupplier:
                navigator.push(.inviteSeller)
            case .supplier:
                navigator.push(.addTransactionRecipient(action: .buy))
            case .buyer:
                navigator.push(.addTransactionRecipient(action: .sell))
        }
    }

    func didTapSave() {
        if !viewModel.isFarmLocationExists() && viewModel.transactionType.isProducer == true {
            viewModel.saveTransactionWithNoLocation()
        } else {
            viewModel.saveTransaction()
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CreateTransactionFormView_Previews: PreviewProvider {
    struct Container: View {
        let transactionType: TransactionType

        init(transactionType: TransactionType) {
            AppContainer.shared.appState.onPreview {
                AppStateImpl(
                    system: .init(inititalValue: .preview),
                    navigation: .init(inititalValue: .preview),
                    transactions: .init(inititalValue: .preview),
                    balance: .init(inititalValue: .preview),
                    createTransaction: .init(inititalValue: .preview),
                    createPassword: .init(inititalValue: .preview),
                    notifications: .init(inititalValue: .preview),
                    notificationsSettings: .init(inititalValue: .preview),
                    profile: .init(inititalValue: .preview),
                    toastManager: AppContainer.shared.toastManager.resolve(),
                    hapticsEngineService: AppContainer.shared.hapticsEngineService.resolve()
                )
            }
            .scope(.unique)
            self.transactionType = transactionType
        }

        var body: some View {
            CreateTransactionFormModule.assemble(transactionType: transactionType)
        }
    }

    static var previews: some View {
        CreateTransactionFormModule.assemble(transactionType: .producer(seller: .farmer(isCurrentlyOnFarm: true)))
            .previewDisplayName("Producer form")
        Container(transactionType: .downstream(action: .sell, recipient: .empty))
            .previewDisplayName("Downstream sell form")
        Container(transactionType: .downstream(action: .buy, recipient: .empty))
            .previewDisplayName("Downstream buy form")
    }
}
#endif
