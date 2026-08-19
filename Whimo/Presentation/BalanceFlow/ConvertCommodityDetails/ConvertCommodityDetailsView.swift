//
//  ConvertCommodityDetailsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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

private typealias Module = ConvertCommodityDetailsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.ConvertCommodityDetails

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var bannerText: String { Localization.Note.title }

        private var balanceDescription: String {
            let balance = "\(viewModel.commodity.balance ?? .zero)"
            let formattedBalance = decimalFormatter.format(value: balance)
            return Localization.FromSection.balance("\(formattedBalance) \(viewModel.commodity.unit)")
        }

        private var enableConvertButton: Bool {
            !viewModel.inputCommodities.contains(where: { Double($0.quantity) ?? .zero == .zero })
        }

        private let decimalFormatter: DecimalFormatter = .default
        private let decimalParser: DecimalNumbersParser = .default

        @FocusState private var keyboardActiveField: KeyboardField?

        // MARK: - Init
        init(commodity: CommodityGroupModel.Commodity, convertionRule: ConversionRuleModel) {
            self._viewModel = .init(wrappedValue: .init(commodity: commodity, convertionRule: convertionRule))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .keyboardDefaultToolbar(action: self.keyboardActiveField = .none)
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
            NoteBanner(text: bannerText)
                .padding(.top, 16)
                .padding(.horizontal, 16)
            ScrollView {
                converterForm()
            }
            AppButton(
                title: Localization.saveButton,
                isEnabled: enableConvertButton,
                action: didTapConvertCommodity
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 16)
            .background {
                if keyboardActiveField == nil {
                    EmptyView()
                } else {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                        .shadow(radius: 7, x: 0, y: 7)
                }
            }
        }
    }

    // MARK: - Convert Form
    @ViewBuilder func converterForm() -> some View {
        VStack(spacing: 24) {
            convertFromSection()
                .padding(.horizontal, 16)
            if !viewModel.outputCommodities.isEmpty {
                DefaultDivider()
                convertToSection()
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 24)
        .background(AppColors.Other.white.colorSwiftUI)
    }

    @ViewBuilder func convertFromSection() -> some View {
        VStack(spacing: 12) {
            ForEach(viewModel.inputCommodities) { rule in
                inputCommoditiewRowView(conversionRule: rule)
                    .onChange(
                        of: viewModel.inputCommodities[id: rule.id]?.quantity
                    ) { [oldValue = viewModel.inputCommodities[id: rule.id]?.quantity] newValue in
                        let oldValue = oldValue ?? ""
                        let newValue = newValue ?? ""
                        let formatted = decimalParser.format(value: newValue)

                        if rule.commodity.id == viewModel.commodity.id,
                           let oldBalance = viewModel.commodity.balance,
                           let newBalance: Double = .init(formatted),
                           newBalance > oldBalance {
                            viewModel.inputCommodities[id: rule.id]?.quantity = oldValue
                            return
                        }

                        if formatted.isEmpty && newValue != formatted {
                            viewModel.inputCommodities[id: rule.id]?.quantity = oldValue
                        } else {
                            viewModel.inputCommodities[id: rule.id]?.quantity = formatted
                        }
                    }
            }
        }
    }

    @ViewBuilder func convertToSection() -> some View {
        VStack(spacing: 12) {
            ForEach(viewModel.outputCommodities) { rule in
                outputCommoditiewRowView(conversionRule: rule)
                    .onChange(
                        of: viewModel.outputCommodities[id: rule.id]?.quantity,
                        perform: { [oldValue = viewModel.outputCommodities[id: rule.id]?.quantity] newValue in
                            let oldValue = oldValue ?? ""
                            let newValue = newValue ?? ""
                            let formatted = decimalParser.format(value: newValue)

                            if formatted.isEmpty && newValue != formatted {
                                viewModel.outputCommodities[id: rule.id]?.quantity = oldValue
                            } else {
                                viewModel.outputCommodities[id: rule.id]?.quantity = formatted
                            }
                        }
                    )
            }
        }
        .animation(.snappy, value: viewModel.outputCommodities)
    }

    // MARK: - Row View
    func inputCommoditiewRowView(conversionRule: Module.MutableConversionRule) -> some View {
        let commodityName: Binding<String> = .init(get: { conversionRule.commodity.name }, set: { _ in })
        let balanceValue: Binding<String> = inputCommodityBinding(conversionRule)
        var commodityDescription: String?
        var balanceDescription: String?
        if conversionRule == viewModel.inputCommodities.first {
            commodityDescription = Localization.FromSection.title
            balanceDescription = self.balanceDescription
        }
        return Module.RowView(
            input: commodityName,
            balanceValue: balanceValue,
            commodityDescription: commodityDescription,
            balanceDescription: balanceDescription,
            units: conversionRule.commodity.unit,
            ruleId: conversionRule.id,
            keyboardActiveField: $keyboardActiveField,
            keyboardField: viewModel.keyboardFields[id: conversionRule.id]
        )
    }

    func outputCommoditiewRowView(conversionRule: Module.MutableConversionRule) -> some View {
        let commodityName: Binding<String> = .init(get: { conversionRule.commodity.name }, set: { _ in })
        let balanceValue: Binding<String> = outputCommodityBinding(conversionRule)
        var commodityDescription: String?
        if conversionRule == viewModel.outputCommodities.first {
            commodityDescription = Localization.ToSection.title
        }
        return Module.RowView(
            output: commodityName,
            balanceValue: balanceValue,
            commodityDescription: commodityDescription,
            units: conversionRule.commodity.unit,
            ruleId: conversionRule.id,
            keyboardActiveField: $keyboardActiveField,
            keyboardField: viewModel.keyboardFields[id: conversionRule.id]
        )
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func inputCommodityBinding(_ сommodity: Module.MutableConversionRule) -> Binding<String> {
        .init {
            сommodity.quantity
        } set: { newValue in
            viewModel.inputCommodities[id: сommodity.id]?.quantity = newValue
        }
    }

    func outputCommodityBinding(_ сommodity: Module.MutableConversionRule) -> Binding<String> {
        .init {
            сommodity.quantity
        } set: { newValue in
            viewModel.outputCommodities[id: сommodity.id]?.quantity = newValue
        }
    }

    func didTapConvertCommodity() { viewModel.didTapConvertCommodity() }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityDetailsView_Previews: PreviewProvider {
    private static let commodity: CommodityGroupModel.Commodity = .init(
        id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
        code: "1401",
        name: "Coffee beans",
        unit: "kgs",
        balance: 123.45,
        hasRecipe: true,
        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
    )

    private static let convertionRule: ConversionRuleModel = .init(
        id: "342c799c-6b32-4c38-8033-085d18b18b2c",
        name: "Roast coffee",
        inputs: [
            .init(
                id: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
                commodity: .init(
                    id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
                    code: "1401",
                    name: "Coffee beans",
                    unit: "kgs",
                    balance: nil,
                    hasRecipe: false,
                    group: .init(
                        id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                        name: "Coffee"
                    )
                ),
                quantity: 10.0
            )
        ],
        outputs: [
            .init(
                id: "26283af0-17da-4c96-8331-dfb372822f87",
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
                quantity: 5.0
            )
        ]
    )

    static var previews: some View {
        ConvertCommodityDetailsModule.assemble(commodity: commodity, convertionRule: convertionRule)
    }
}
#endif
