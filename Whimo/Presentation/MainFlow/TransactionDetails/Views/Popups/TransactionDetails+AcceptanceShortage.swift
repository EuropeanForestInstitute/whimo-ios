//
//  TransactionDetails+AcceptanceShortage.swift
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

private typealias Localization = AppLocale.TransactionAcceptance.Balance

extension TransactionDetailsModule {
    struct AcceptanceAutomaticPreview: Equatable {
        let quantity: Double
        let unit: String

        func summary(locale: Locale) -> AttributedString {
            let amount = quantity.formatted(.number.locale(locale)) + " " + unit
            var result = AttributedString(AppLocale.TransactionAcceptance.Preview.message(amount))
            for phrase in [AppLocale.TransactionAcceptance.Preview.automaticTransaction,
                           AppLocale.TransactionAcceptance.Preview.incompleteTraceability] {
                if let range = result.range(of: phrase) { result[range].font = FontBuilder.buildMedium(size: 14) }
            }
            return result
        }
    }

    struct AcceptanceShortage: Equatable {
        let available: Double
        let requested: Double
        let unit: String
        let season: HarvestSeason

        func summary(locale: Locale) -> AttributedString {
            let availableAmount = available.formatted(.number.locale(locale)) + " " + unit
            let requestedAmount = requested.formatted(.number.locale(locale)) + " " + unit
            var result = AttributedString(Localization.summary(availableAmount, season.name, requestedAmount))
            for amount in [availableAmount, requestedAmount] {
                if let range = result.range(of: amount) { result[range].font = FontBuilder.buildMedium(size: 14) }
            }
            return result
        }
    }

    struct AcceptanceShortagePopup: View {
        let shortage: AcceptanceShortage
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(shortage.summary(locale: currentLocalize.locale))
                Text(Localization.requirement)
                Text(Localization.alternative)
            }
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .fitToScrollView()
        }
    }
}
