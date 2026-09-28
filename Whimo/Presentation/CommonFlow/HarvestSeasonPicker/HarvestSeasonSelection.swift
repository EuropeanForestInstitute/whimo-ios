//
//  HarvestSeasonSelection.swift
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

import Foundation

// MARK: - HarvestSeasonSelection
enum HarvestSeasonSelection: Identifiable, Equatable {
    enum SelectionID: Hashable {
        case harvestSeason(String)
        case all
    }

    case harvestSeason(HarvestSeason)
    case all

    var id: SelectionID {
        switch self {
            case .harvestSeason(let harvestSeason):
                .harvestSeason(harvestSeason.id)
            case .all:
                .all
        }
    }

    var periodTitle: String? {
        switch self {
            case .harvestSeason(let harvestSeason):
                HarvestSeasonPeriodFormatter.title(for: harvestSeason)
            case .all:
                nil
        }
    }

    var status: HarvestSeasonStatus? {
        switch self {
            case .harvestSeason(let harvestSeason):
                harvestSeason.status
            case .all:
                nil
        }
    }

    func title(using localization: HarvestSeasonPickerLocalization) -> String {
        switch self {
            case .harvestSeason(let harvestSeason):
                return localization.seasonTitle(
                    period: HarvestSeasonPeriodFormatter.title(for: harvestSeason)
                )
            case .all:
                return localization.allTitle
        }
    }

    func accessibleTitle(using localization: HarvestSeasonPickerLocalization) -> String {
        if case .harvestSeason(let season) = self {
            let name = season.name.isEmpty ? title(using: localization) : season.name
            return "\(name), \(localization.statusPresentation(for: season.status).title)"
        }
        return localization.allTitle
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - HarvestSeasonPeriodFormatter
private enum HarvestSeasonPeriodFormatter {
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = .gmt
        return calendar
    }()

    static func title(for harvestSeason: HarvestSeason) -> String {
        let startYear = calendar.component(.year, from: harvestSeason.startDate)
        let endYear = calendar.component(.year, from: harvestSeason.endDate)

        return String(
            format: "%04d/%02d",
            locale: locale,
            startYear,
            endYear % 100
        )
    }
}
