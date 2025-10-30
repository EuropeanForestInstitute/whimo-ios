//
//  BalanceGroupDetails+CommodityRow.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 15.08.2025.
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
import Resources

private typealias Module = BalanceGroupDetailsModule
private typealias CommodityRow = Module.CommodityRow

// MARK: - RowItemsList
extension Module {
    struct CommodityRow: View {
        // MARK: - Properties
        let item: CommodityGroupModel.Commodity

        // MARK: - Private Properties
        private let decimalFormatter: DecimalFormatter = .shortFraction

        var balanceText: String {
            let stringBalance = decimalFormatter.format(value: "\(item.balance ?? .zero)")
            return "\(stringBalance)\(item.unit)"
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
private extension CommodityRow {
    @ViewBuilder func content() -> some View {
        label()
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
    }

    @ViewBuilder func label() -> some View {
        HStack(alignment: .top) {
            Group {
                Text(item.code)
                Text(item.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .appFontRegularSize14()
            Text(balanceText)
                .appFontMediumSize14()
        }
        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
    }
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupDetailsCommodityRow_Previews: PreviewProvider {
    private static let item: CommodityGroupModel.Commodity = .init(
        id: "1",
        code: "1801",
        name: "Cocoa beans, whole or broken, raw or roasted",
        unit: "",
        balance: nil
    )
    private static let item2: CommodityGroupModel.Commodity = .init(
        id: "1",
        code: "1805",
        name: "Cocoa powder, not containing added sugar or other sweetening matter",
        unit: "",
        balance: nil
    )

    static var previews: some View {
        VStack {
            CommodityRow(item: item)
            CommodityRow(item: item2)
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
