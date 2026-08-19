//
//  CommoditiesList+RowListItem.swift
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

private typealias Module = CommoditiesListModule
private typealias RowListItem = Module.RowListItem
private typealias Assets = AppAssets.CommodityType
private typealias Localization = AppLocale.CommoditiesList.Row

// MARK: - RowItemsList
extension Module {
    struct RowListItem: View {
        // MARK: - Properties
        let item: CommodityGroupModel.Commodity
        @Binding var selectedItem: CommodityGroupModel.Commodity?

        // MARK: - Private Properties
        private let decimalFormatter: DecimalFormatter = .shortFraction

        var balanceCount: Double { item.balance ?? .zero }
        var balanceText: String {
            let stringBalance = decimalFormatter.format(value: "\(balanceCount)")
            return Localization.balanceCount("\(stringBalance)\(item.unit)")
        }
        var balanceTextColor: Color {
            balanceCount > .zero
            ? AppColors.Gray.gray60.colorSwiftUI
            : AppColors.Expanded.expandedWarning.colorSwiftUI
        }

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    AppColors.Other.white.colorSwiftUI
                }
        }
    }
}

// MARK: - Private Layout
private extension RowListItem {
    @ViewBuilder func content() -> some View {
        Button {
            selectedItem = item
        } label: {
            label()
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
    }

    @ViewBuilder func label() -> some View {
        HStack(alignment: .top) {
            Text(item.code)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Text(balanceText)
                    .appFontRegularSize12()
                    .foregroundStyle(balanceTextColor)
            }
            selectionAccessory()
        }
        .appFontRegularSize14()
        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
    }

    @ViewBuilder func selectionAccessory() -> some View {
        if selectedItem == item {
            Assets.commodityTypeSelectedAccessory.imageSwiftUI
        } else {
            Assets.commodityTypeSelectedAccessory.imageSwiftUI
                .hidden()
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CommoditiesListRowItemsList_Previews: PreviewProvider {
    private static let item1: CommodityGroupModel.Commodity = .init(
        id: "1",
        code: "1805",
        name: "Cocoa powder, not containing added sugar or other sweetening matter",
        unit: "kg",
        balance: nil,
        hasRecipe: true,
        group: .init(id: "1", name: "Cocoa")
    )
    private static let item2: CommodityGroupModel.Commodity = .init(
        id: "1",
        code: "1806",
        name: "Chocolate and other food preparations containing cocoa",
        unit: "kg",
        balance: 12.2,
        hasRecipe: true,
        group: .init(id: "1", name: "Cocoa")
    )

    static var previews: some View {
        VStack {
            RowListItem(item: item1, selectedItem: .constant(nil))
            RowListItem(item: item2, selectedItem: .constant(item2))
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
