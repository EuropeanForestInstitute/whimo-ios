//
//  HarvestSeasonPickerLocalization.swift
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
import Resources

// MARK: - HarvestSeasonStatusPresentation
struct HarvestSeasonStatusPresentation {
    let title: String
    let foregroundColor: Color
    let backgroundColor: Color
}

// MARK: - HarvestSeasonPickerLocalization
struct HarvestSeasonPickerLocalization {
    private static let prefixToken = "__HARVEST_SEASON_PREFIX__"
    private static let periodToken = "__HARVEST_SEASON_PERIOD__"
    private static let titleToken = "__HARVEST_SEASON_TITLE__"
    private static let statusToken = "__HARVEST_SEASON_STATUS__"

    let allTitle: String
    let expandedTitle: String
    let collapsedTitle: String

    private let activeTitle: String
    private let pastTitle: String
    private let archivedTitle: String
    private let seasonTitlePrefix: String
    private let seasonTitleTemplate: String
    private let accessibleRowTitleTemplate: String

    static var current: Self {
        Self(
            allTitle: AppLocale.HarvestSeasonPicker.All.title,
            expandedTitle: AppLocale.HarvestSeasonPicker.Disclosure.expanded,
            collapsedTitle: AppLocale.HarvestSeasonPicker.Disclosure.collapsed,
            activeTitle: AppLocale.HarvestSeasonPicker.Status.active,
            pastTitle: AppLocale.HarvestSeasonPicker.Status.past,
            archivedTitle: AppLocale.HarvestSeasonPicker.Status.archived,
            seasonTitlePrefix: AppLocale.HarvestSeasonPicker.Season.title,
            seasonTitleTemplate: AppLocale.HarvestSeasonPicker.Season.fullTitle(
                prefixToken,
                periodToken
            ),
            accessibleRowTitleTemplate: AppLocale.HarvestSeasonPicker.Accessibility.rowTitle(
                titleToken,
                statusToken
            )
        )
    }

    func seasonTitle(period: String) -> String {
        seasonTitleTemplate
            .replacingOccurrences(of: Self.prefixToken, with: seasonTitlePrefix)
            .replacingOccurrences(of: Self.periodToken, with: period)
    }

    func statusPresentation(for status: HarvestSeasonStatus) -> HarvestSeasonStatusPresentation {
        switch status {
            case .active:
                HarvestSeasonStatusPresentation(
                    title: activeTitle,
                    foregroundColor: AppColors.Expanded.expandedSuccess.colorSwiftUI,
                    backgroundColor: AppColors.Other.lightGreen.colorSwiftUI
                )
            case .past:
                HarvestSeasonStatusPresentation(
                    title: pastTitle,
                    foregroundColor: AppColors.Expanded.expandedWarning.colorSwiftUI,
                    backgroundColor: AppColors.Other.lightOrange.colorSwiftUI
                )
            case .archive:
                HarvestSeasonStatusPresentation(
                    title: archivedTitle,
                    foregroundColor: AppColors.Gray.gray60.colorSwiftUI,
                    backgroundColor: AppColors.Gray.gray10.colorSwiftUI
                )
        }
    }

    func accessibleRowTitle(title: String, statusTitle: String) -> String {
        accessibleRowTitleTemplate
            .replacingOccurrences(of: Self.titleToken, with: title)
            .replacingOccurrences(of: Self.statusToken, with: statusTitle)
    }

    func disclosureTitle(isExpanded: Bool) -> String {
        isExpanded ? expandedTitle : collapsedTitle
    }
}

// MARK: - Preview Fixtures
#if !RELEASE
extension HarvestSeasonPickerLocalization {
    private struct PreviewCopy {
        let seasonTitle: String
        let allTitle: String
        let activeTitle: String
        let pastTitle: String
        let archivedTitle: String
        let expandedTitle: String
        let collapsedTitle: String
    }

    static func preview(language: LocalizeKeys) -> Self {
        switch language {
            case .english:
                preview(.init(
                    seasonTitle: "Harvest season", allTitle: "All harvest seasons",
                    activeTitle: "Active", pastTitle: "Past", archivedTitle: "Archived",
                    expandedTitle: "Expanded", collapsedTitle: "Collapsed"
                ))
            case .french:
                preview(.init(
                    seasonTitle: "Saison de récolte", allTitle: "Toutes les saisons de récolte",
                    activeTitle: "Active", pastTitle: "Passée", archivedTitle: "Archivée",
                    expandedTitle: "Développé", collapsedTitle: "Réduit"
                ))
            case .spanish:
                preview(.init(
                    seasonTitle: "Temporada de cosecha", allTitle: "Todas las temporadas de cosecha",
                    activeTitle: "Activa", pastTitle: "Pasada", archivedTitle: "Archivada",
                    expandedTitle: "Expandido", collapsedTitle: "Contraído"
                ))
        }
    }

    private static func preview(_ copy: PreviewCopy) -> Self {
        Self(
            allTitle: copy.allTitle,
            expandedTitle: copy.expandedTitle,
            collapsedTitle: copy.collapsedTitle,
            activeTitle: copy.activeTitle,
            pastTitle: copy.pastTitle,
            archivedTitle: copy.archivedTitle,
            seasonTitlePrefix: copy.seasonTitle,
            seasonTitleTemplate: "\(prefixToken) \(periodToken)",
            accessibleRowTitleTemplate: "\(titleToken), \(statusToken)"
        )
    }
}
#endif
