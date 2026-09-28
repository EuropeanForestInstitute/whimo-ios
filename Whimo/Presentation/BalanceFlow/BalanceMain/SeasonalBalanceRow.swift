//
//  SeasonalBalanceRow.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 19.08.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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

struct SeasonalBalanceRow: View {
    let row: SeasonalBalance
    let canConvert: Bool
    let openDetails: () -> Void
    let convert: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let titleSize: CGFloat = 16
    private let codeSize: CGFloat = 12

    private var quantity: String {
        DecimalFormatter.default.format(value: String(row.volume)) + row.commodity.unit
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: openDetails) { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
            conversionButton.padding(.top, 14).padding(.trailing, 16)
        }
        .accessibilityElement(children: .contain)
    }

    private var conversionButton: some View {
        Button(action: convert) {
            AppAssets.Balance.balanceConvertIcon.imageSwiftUI
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        .disabled(!canConvert || !row.hasRecipe)
        .opacity(row.hasRecipe ? (canConvert ? 1 : 0.4) : 0)
        .accessibilityHidden(!row.hasRecipe)
        .accessibilityLabel(AppLocale.SeasonalBalance.convert(row.commodity.name))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(row.commodity.code)
                        .font(FontBuilder.buildRegular(size: codeSize))
                        .lineLimit(1)
                        .frame(width: 40, alignment: .leading)
                        .accessibilityLabel(row.commodity.code)
                }
                VStack(alignment: .leading, spacing: 8) {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text(row.commodity.code).font(FontBuilder.buildRegular(size: codeSize))
                    }
                    Text(row.commodity.name)
                        .font(FontBuilder.buildMedium(size: titleSize))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(quantity).font(FontBuilder.buildMedium(size: titleSize)).fixedSize()
                }
                Color.clear.frame(width: 28, height: 28)
            }
            VStack(alignment: .leading, spacing: 8) {
                if dynamicTypeSize.isAccessibilitySize {
                    Text(quantity).font(FontBuilder.buildMedium(size: titleSize))
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) { badges }
                    VStack(alignment: .leading, spacing: 6) { badges }
                }
            }
            .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 48)
        }
        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.Other.white.colorSwiftUI)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var badges: some View {
        TransactionSeasonBadge(season: row.season, fontSize: 14, verticalPadding: 4)
        if let traceability = row.traceability {
            Text(traceability.title)
                .font(FontBuilder.buildMedium(size: 14))
                .foregroundStyle(traceability.primaryColor)
                .padding(.horizontal, 6).padding(.vertical, 4)
                .background(traceability.secondaryColor, in: .rect(cornerRadius: 3))
                .accessibilityLabel(traceability.fullTitle)
        }
    }
}
