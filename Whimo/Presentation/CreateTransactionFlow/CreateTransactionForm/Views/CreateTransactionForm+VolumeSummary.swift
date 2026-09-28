//
//  CreateTransactionForm+VolumeSummary.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 08.09.2026.
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

private typealias Module = CreateTransactionFormModule
private typealias Localization = AppLocale.CreateTransactionForm.VolumeSummary

extension Module {
    struct VolumeSummary: View {
        let volume: String
        let season: HarvestSeason
        let transactionType: TransactionType
        var message: String?
        var isCached = false

        private var presentation: TransactionSeasonPresentation { .init(season: season) }
        private var caption: String {
            switch transactionType {
                case .producer: Localization.transactionIncludes
                case .downstream(.buy, _): Localization.purchaseIncludes
                case .downstream(.sell, _): Localization.saleIncludes
            }
        }
        private var amountDescription: AttributedString {
            var amount = AttributedString(volume)
            amount.font = FontBuilder.buildMedium(size: 14)
            return message == nil ? amount + AttributedString(" " + Localization.fromSeason(presentation.title)) : amount
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(caption)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(amountDescription)
                        .appFontRegularSize14()
                        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if let status = presentation.status {
                        VolumeStatusBadge(status: status)
                            .fixedSize()
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(volume), \(presentation.accessibilityLabel)")
                if let message {
                    Text(message)
                        .appFontRegularSize14()
                        .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if isCached {
                    Text(Localization.savedBalance)
                        .appFontRegularSize14()
                        .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

extension Module {
    struct SaleVolumeSummary: View {
        let breakdown: SaleVolumeBreakdown
        let unit: String
        let season: HarvestSeason
        let isCached: Bool
        let edit: () -> Void
        let showAutomaticInfo: () -> Void

        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        private var presentation: TransactionSeasonPresentation { .init(season: season) }
        private var showsSeason: Bool { breakdown.showsSeason }
        private var accessibilityValue: String {
            var parts = [Localization.saleIncludes, presentation.accessibilityLabel]
            if showsSeason { parts.append(amount(breakdown.seasonVolume) + " " + Localization.fromSeason(presentation.title)) }
            if breakdown.showsAutomatic { parts.append(amount(breakdown.automaticVolume) + " " + Localization.automatic) }
            if isCached { parts.append(Localization.savedBalance) }
            return parts.joined(separator: ", ")
        }

        var body: some View {
            ZStack {
                Button(action: edit) {
                    Color.clear.contentShape(Rectangle())
                }
                .accessibilityLabel(Localization.edit)
                .accessibilityValue(accessibilityValue)
                .accessibilityIdentifier("sale-volume-edit")
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Module.Row.volume.leadingAccessory.frame(width: 24, height: 24)
                        Text(AppLocale.CreateTransactionForm.Row.Volumes.title)
                            .font(FontBuilder.buildMedium(size: 16))
                        + Text(AppLocale.CreateTransactionForm.Row.Volumes.titleSuffix)
                            .foregroundColor(AppColors.Expanded.expandedError.colorSwiftUI)
                        Spacer(minLength: 0)
                        AppAssets.Shared.sharedChevronRight.imageSwiftUI.frame(width: 24, height: 24)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Localization.saleIncludes)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                        if showsSeason { component(volume: breakdown.seasonVolume, isAutomatic: false) }
                        if breakdown.showsAutomatic { component(volume: breakdown.automaticVolume, isAutomatic: true) }
                        if isCached {
                            Text(Localization.savedBalance)
                                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                                .fixedSize(horizontal: false, vertical: true)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.leading, 32)
                }
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .padding(16)
            }
            .buttonStyle(.plain)
            .background(AppColors.Other.white.colorSwiftUI)
            .multilineTextAlignment(.leading)
        }

        private func amount(_ volume: String) -> String {
            Module.volumeDescription(volume, unit: unit, locale: currentLocalize.locale)
        }

        @ViewBuilder private func component(volume: String, isAutomatic: Bool) -> some View {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .center, spacing: 8))
            layout {
                Text(description(volume: volume, isAutomatic: isAutomatic))
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .padding(.trailing, isAutomatic ? 44 : 0)
                    .overlay(alignment: .trailing) {
                        if isAutomatic {
                            Button(action: showAutomaticInfo) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(AppColors.Expanded.expandedWarning.colorSwiftUI)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel(AppLocale.CreateTransactionForm.Automatic.title)
                            .accessibilityIdentifier("sale-volume-automatic-info")
                        }
                    }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if let status = presentation.status {
                    VolumeStatusBadge(status: status)
                        .fixedSize(horizontal: false, vertical: true)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }

        private func description(volume: String, isAutomatic: Bool) -> AttributedString {
            var quantity = AttributedString(amount(volume))
            quantity.font = FontBuilder.buildMedium(size: 14)
            let source = isAutomatic ? Localization.automatic : Localization.fromSeason(presentation.title)
            return quantity + AttributedString(" " + source)
        }
    }

    struct AutomaticInfoPopup: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocale.CreateTransactionForm.Automatic.explanation)
                Text(AppLocale.CreateTransactionForm.Automatic.review)
                Text(AppLocale.CreateTransactionForm.Automatic.estimate)
            }
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .fitToScrollView()
        }
    }
}

extension Module {
    static func volumeDescription(_ volume: String, unit: String, locale: Locale) -> String {
        volume.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".") + " " + unit
    }
}

private struct VolumeStatusBadge: View {
    let status: HarvestSeasonStatusPresentation

    var body: some View {
        Text(status.title)
            .font(FontBuilder.buildMedium(size: 12))
            .foregroundStyle(status.foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.backgroundColor, in: .rect(cornerRadius: 3))
    }
}
