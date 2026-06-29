//
//  CommodityVolumeView.swift
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

private typealias Module = CommodityVolumeModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.CommodityVolume

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

        private let decimalParser: DecimalNumbersParser = .default
        private let decimalFormatterShort: DecimalFormatter = .shortFraction

        private var titleText: String {
            "\(viewModel.commodityType.code) \(viewModel.commodityType.name)"
        }
        private var balanceText: String {
            let stringBalance = decimalFormatterShort.format(value: "\(viewModel.commodityType.balance ?? .zero)")
            return Localization.balanceAmount("\(stringBalance)\(viewModel.commodityType.unit)")
        }
        private var isConfirmButtonEnabled: Bool {
            !viewModel.volumeText.isEmpty
        }

        // MARK: - Init
        init(
            volumeAmount: String,
            commodityType: CommodityGroupModel.Commodity,
            transactionType: TransactionType
        ) {
            self._viewModel = .init(wrappedValue: .init(
                volumeAmount: volumeAmount,
                commodityType: commodityType,
                transactionType: transactionType
            ))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
                .keyboardDefaultToolbar(action: self.keyboardActiveField = .none)
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    header()
                        .padding(.top, 16)
                    VStack(alignment: .leading, spacing: 4) {
                        textFields()
                        Text(balanceText)
                            .appFontRegularSize14()
                            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                    }
                    if viewModel.enableNoteBanner {
                        NoteBanner(text: Localization.Note.text, state: .warning)
                    }
                }
                .padding(.horizontal, 16)
            }
            confirmButton()
        }
    }

    @ViewBuilder func header() -> some View {
        HStack(spacing: 12) {
            Text(titleText)
                .appFontMediumSize18()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
                .frame(width: 32)
            Button {
                didTapEdit()
            } label: {
                Text(Localization.Buttons.edit)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
        }
    }

    @ViewBuilder func textFields() -> some View {
        HStack(spacing: 12) {
            AppTextField(
                text: $viewModel.volumeText,
                description: Localization.TextFields.Weight.description,
                placeholder: Localization.TextFields.Weight.placeholder
            )
            .onChange(of: viewModel.volumeText, perform: { [oldValue = viewModel.volumeText] newValue in
                let formatted = decimalParser.format(value: newValue)

                if formatted.isEmpty && newValue != formatted {
                    viewModel.volumeText = oldValue
                } else {
                    viewModel.volumeText = formatted
                }
            })
            .focused($keyboardActiveField, equals: .amount)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            AppTextField(
                text: .constant(viewModel.commodityType.unit),
                description: Localization.TextFields.Unit.description,
                state: .disabled,
                tapDestination: .textField(keyboardActiveField = .amount),
            )
            .disabled(true)
            .frame(width: 100)
        }
    }

    @ViewBuilder func confirmButton() -> some View {
        AppButton(
            title: Localization.Buttons.confirm,
            isEnabled: isConfirmButtonEnabled,
            action: didTapConfirm
        )
        .padding(.top, 12)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .animation(.snappy, value: isConfirmButtonEnabled)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapEdit() {
        navigator.push(.commoditiesList)
    }

    func didTapConfirm() {
        viewModel.didTapConfirm()
    }
}

// MARK: - Previews
#if !RELEASE
struct CommodityVolumeView_Previews: PreviewProvider {
    struct Container: View {
        let transactionType: TransactionType

        init(transactionType: TransactionType) {
            self.transactionType = transactionType
        }

        var body: some View {
            CommodityVolumeModule.assemble(volumeAmount: "", commodityType: .initialState, transactionType: transactionType)
        }
    }

    static var previews: some View {
        Container(transactionType: .producer(seller: .farmer(isCurrentlyOnFarm: true)))
    }
}
#endif
