//
//  TransactionSeasonPresentation.swift
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

struct TransactionSeasonPresentation {
    let season: HarvestSeason?

    var title: String {
        season.map { HarvestSeasonSelection.harvestSeason($0).periodTitle ?? $0.name }
            ?? AppLocale.TransactionSeason.unavailable
    }

    var accessibilityLabel: String {
        guard let season else { return AppLocale.TransactionSeason.unavailable }

        return HarvestSeasonPickerLocalization.current.accessibleRowTitle(
            title: season.name,
            statusTitle: HarvestSeasonPickerLocalization.current.statusPresentation(for: season.status).title
        )
    }

    var status: HarvestSeasonStatusPresentation? {
        guard let season else { return nil }

        var value = HarvestSeasonPickerLocalization.current.statusPresentation(for: season.status)
        switch season.status {
            case .active:
                value = .init(title: value.title, foregroundColor: AppColors.HarvestSeason.seasonActiveText.colorSwiftUI,
                              backgroundColor: AppColors.HarvestSeason.seasonActiveFill.colorSwiftUI)
            case .past:
                value = .init(title: value.title, foregroundColor: AppColors.HarvestSeason.seasonPastText.colorSwiftUI,
                              backgroundColor: AppColors.HarvestSeason.seasonPastFill.colorSwiftUI)
            case .archive:
                break
        }
        return value
    }

    func dateRange(locale: Locale) -> String? {
        guard let season else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        guard let lastDate = calendar.date(byAdding: .day, value: -1, to: season.endDate) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.dateStyle = .medium
        return formatter.string(from: season.startDate) + " – " + formatter.string(from: lastDate)
    }
}

struct TransactionSeasonBadge: View {
    let season: HarvestSeason?
    var includesStatus = false
    var fontSize: CGFloat = 12
    var verticalPadding: CGFloat = 2

    private var presentation: TransactionSeasonPresentation { .init(season: season) }
    private var status: HarvestSeasonStatusPresentation? {
        presentation.status
    }

    var body: some View {
        Text(badgeTitle)
            .font(FontBuilder.buildMedium(size: fontSize))
            .foregroundStyle(status?.foregroundColor ?? AppColors.Gray.gray60.colorSwiftUI)
            .padding(.horizontal, 6)
            .padding(.vertical, verticalPadding)
            .background(status?.backgroundColor ?? AppColors.Gray.gray10.colorSwiftUI, in: .rect(cornerRadius: 3))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(presentation.accessibilityLabel)
    }

    private var badgeTitle: String {
        guard includesStatus, let status else { return presentation.title }

        return AppLocale.TransactionSeason.badge(status.title, presentation.title)
    }
}
