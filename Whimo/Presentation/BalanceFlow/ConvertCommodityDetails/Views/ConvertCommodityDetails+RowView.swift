//
//  ConvertCommodityDetails+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.11.2025.
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

private typealias Module = ConvertCommodityDetailsModule
private typealias RowView = Module.RowView

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Configuration
        enum Configuration {
            case input(balanceDescription: String?)
            case output
        }

        // MARK: - Properties
        @Binding var commodityName: String
        @Binding var balanceValue: String

        let configuration: Configuration
        let commodityDescription: String?
        let units: String
        let ruleId: String
        var keyboardActiveField: FocusState<KeyboardField?>.Binding
        let keyboardField: KeyboardField?

        // MARK: - Computed Properties
        private var displayDescriptionView: Bool {
            !(commodityDescription == nil && balanceDescription == nil)
        }

        private var balanceDescription: String? {
            switch configuration {
                case .input(let balanceDescription):
                    return balanceDescription
                case .output:
                    return nil
            }
        }

        // MARK: - Init Input
        init(
            input commodityName: Binding<String>,
            balanceValue: Binding<String>,
            commodityDescription: String? = nil,
            balanceDescription: String? = nil,
            units: String,
            ruleId: String,
            keyboardActiveField: FocusState<KeyboardField?>.Binding,
            keyboardField: KeyboardField?
        ) {
            self.configuration = .input(balanceDescription: balanceDescription)
            self._commodityName = commodityName
            self._balanceValue = balanceValue
            self.commodityDescription = commodityDescription
            self.units = units
            self.ruleId = ruleId
            self.keyboardActiveField = keyboardActiveField
            self.keyboardField = keyboardField
        }

        // MARK: - Init Output
        init(
            output commodityName: Binding<String>,
            balanceValue: Binding<String>,
            commodityDescription: String? = nil,
            units: String,
            ruleId: String,
            keyboardActiveField: FocusState<KeyboardField?>.Binding,
            keyboardField: KeyboardField?
        ) {
            self.configuration = .output
            self._commodityName = commodityName
            self._balanceValue = balanceValue
            self.commodityDescription = commodityDescription
            self.units = units
            self.ruleId = ruleId
            self.keyboardActiveField = keyboardActiveField
            self.keyboardField = keyboardField
        }

        // MARK: - Body
        var body: some View {
            GeometryReader { proxy in
                VStack(spacing: 4) {
                    if displayDescriptionView {
                        descriptionRow()
                    }
                    textFieldsRow(proxy: proxy)
                }
            }
            .frame(height: displayDescriptionView ? 70 : 48)
            .frame(maxHeight: 70)
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func descriptionRow() -> some View {
        HStack {
            if let commodityDescription {
                Text(commodityDescription)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            if let balanceDescription {
                Text(balanceDescription)
                    .appFontRegularSize12()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(height: 18)
    }

    @ViewBuilder func textFieldsRow(proxy: GeometryProxy) -> some View {
        HStack(spacing: 12) {
            AppTextField(text: $commodityName)
                .frame(width: proxy.size.width * 0.7)
                .disabled(true)
            AppTextField(
                trailingItem: .custom(content: .init(unitText(units: units))),
                text: $balanceValue
            )
            .focused(keyboardActiveField, equals: keyboardField)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
        }
    }

    @ViewBuilder func unitText(units: String) -> some View {
        Text(units)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityDetailsRowView_Previews: PreviewProvider {
    private static let mockCommodity: CommodityGroupModel.Commodity = .init(
        id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
        code: "1401",
        name: "Coffee beans",
        unit: "kgs",
        balance: 123.45,
        hasRecipe: true,
        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
    )

    private static let mockKeyboardField: Module.KeyboardField = .init(
        id: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
        name: "Coffee beans"
    )

    struct Container: View {
        @State private var commodityName: String = "Coffee beans"
        @State private var balanceValue: String = "10.0"
        @FocusState private var keyboardActiveField: Module.KeyboardField?

        var body: some View {
            VStack(spacing: 20) {
                RowView(
                    input: $commodityName,
                    balanceValue: $balanceValue,
                    commodityDescription: "From",
                    balanceDescription: "Your balance: 123.45 kgs",
                    units: "kgs",
                    ruleId: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
                    keyboardActiveField: $keyboardActiveField,
                    keyboardField: mockKeyboardField
                )

                RowView(
                    output: $commodityName,
                    balanceValue: $balanceValue,
                    commodityDescription: "To",
                    units: "buckets",
                    ruleId: "26283af0-17da-4c96-8331-dfb372822f87",
                    keyboardActiveField: $keyboardActiveField,
                    keyboardField: mockKeyboardField
                )
            }
            .padding()
            .background(AppColors.Gray.gray5.colorSwiftUI)
        }
    }

    static var previews: some View {
        Container()
    }
}
#endif
