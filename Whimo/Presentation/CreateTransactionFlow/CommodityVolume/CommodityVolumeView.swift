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
        @StateObject private var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        // MARK: - Private Properties
        @State private var seasonPickerPresented = false
        @FocusState private var keyboardActiveField: KeyboardField?

        private let decimalParser: DecimalNumbersParser = .default
        private let decimalFormatterShort: DecimalFormatter = .shortFraction

        private var titleText: String {
            "\(viewModel.commodityType.code) \(viewModel.commodityType.name)"
        }
        private var balanceText: String {
            if viewModel.requiresSeason, viewModel.seasonalBalance == nil {
                return AppLocale.CreationSeason.balanceUnavailable
            }
            let balance = viewModel.requiresSeason ? viewModel.seasonalBalance?.volume : viewModel.commodityType.balance
            let stringBalance = decimalFormatterShort.format(value: "\(balance ?? .zero)")
            return Localization.balanceAmount("\(stringBalance)\(viewModel.commodityType.unit)")
        }
        private var isConfirmButtonEnabled: Bool {
            viewModel.canConfirm
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
                .task(id: viewModel.commodityType.id) { await viewModel.loadSeasons() }
                .task(id: "\(viewModel.commodityType.id):\(viewModel.selectedSeason?.id ?? ""):\(viewModel.isLoadingSeasons)") {
                    await viewModel.loadBalance()
                }
                .onChange(of: seasonPickerPresented) { isPresented in
                    if isPresented { keyboardActiveField = nil }
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
                    if viewModel.requiresSeason {
                        seasonPicker()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        textFields()
                        Text(balanceText)
                            .appFontRegularSize14()
                            .foregroundStyle(viewModel.hasSeasonalShortage ? .red : AppColors.Gray.gray60.colorSwiftUI)
                    }
                    if viewModel.hasSeasonalShortage {
                        NoteBanner(text: AppLocale.CreationSeason.insufficientBalance(
                            TransactionSeasonPresentation(season: viewModel.selectedSeason).title
                        ), state: .warning)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(AppLocale.CreationSeason.insufficientBalance(viewModel.selectedSeason?.name ?? ""))
                    } else if viewModel.enableNoteBanner {
                        NoteBanner(text: Localization.Note.text, state: .warning)
                    } else if viewModel.isSelling, viewModel.balanceUnavailable {
                        Button(AppLocale.CreationSeason.retry) { Task { await viewModel.loadBalance() } }
                    }
                    if viewModel.seasonalBalance?.isCached == true {
                        Text(AppLocale.CreationSeason.cachedBalance)
                            .appFontRegularSize14()
                            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
            }
            confirmButton()
        }
    }

    @ViewBuilder func seasonPicker() -> some View {
        if !viewModel.seasons.isEmpty {
            HarvestSeasonPicker(
                harvestSeasons: viewModel.seasons,
                selectedSelection: viewModel.selectedSeason.map(HarvestSeasonSelection.harvestSeason),
                isPresented: $seasonPickerPresented,
                includesAll: false
            ) { selection in
                if case .harvestSeason(let season) = selection { viewModel.selectSeason(season) }
            }
        } else if viewModel.isLoadingSeasons {
            ProgressView().frame(maxWidth: .infinity, minHeight: 48)
        } else if viewModel.catalogueUnavailable {
            NoteBanner(text: AppLocale.CreationSeason.catalogueRequired, state: .warning)
            Button(AppLocale.CreationSeason.retry) {
                Task { await viewModel.loadSeasons() }
            }
        }
    }

    @ViewBuilder func header() -> some View {
        HStack(spacing: 12) {
            Text(titleText)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                didTapEdit()
            } label: {
                AppAssets.BuyTxOnFarmDialog.buyTxOnFarmDialogPencilIcon.imageSwiftUI
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppColors.Gray.gray50.colorSwiftUI)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder func textFields() -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            AppTextField(
                text: $viewModel.volumeText,
                description: Localization.TextFields.Weight.description,
                placeholder: Localization.TextFields.Weight.placeholder,
                state: viewModel.hasSeasonalShortage ? .failed(errorText: "") : .default
            )
            .onChange(of: viewModel.volumeText, perform: { [oldValue = viewModel.volumeText] newValue in
                let formatted = decimalParser.format(value: newValue)

                if formatted.isEmpty && newValue != formatted {
                    viewModel.volumeText = oldValue
                } else {
                    viewModel.volumeText = formatted
                }
            })
            .accessibilityLabel(Localization.TextFields.Weight.description)
            .focused($keyboardActiveField, equals: .amount)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            AppTextField(
                text: .constant(viewModel.commodityType.unit),
                description: Localization.TextFields.Unit.description,
                state: .disabled,
                tapDestination: .textField(keyboardActiveField = .amount),
            )
            .accessibilityLabel(Localization.TextFields.Unit.description)
            .disabled(true)
            .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 100)
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
