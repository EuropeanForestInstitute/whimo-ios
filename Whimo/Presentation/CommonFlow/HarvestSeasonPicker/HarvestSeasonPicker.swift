//
//  HarvestSeasonPicker.swift
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

// MARK: - HarvestSeasonPicker
struct HarvestSeasonPicker: View {
    // MARK: - Private Properties
    @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english
    @Binding private var isPresented: Bool

    private let harvestSeasons: [HarvestSeason]
    private let selectedSelection: HarvestSeasonSelection?
    private let includesAll: Bool
    private let localizationOverride: HarvestSeasonPickerLocalization?
    private let onSelect: (HarvestSeasonSelection) -> Void

    private var selections: [HarvestSeasonSelection] {
        harvestSeasons.map(HarvestSeasonSelection.harvestSeason) + (includesAll ? [.all] : [])
    }

    private var localization: HarvestSeasonPickerLocalization {
        _ = currentLocalize
        return localizationOverride ?? .current
    }

    // MARK: - Init
    init(
        harvestSeasons: [HarvestSeason],
        selectedSelection: HarvestSeasonSelection?,
        isPresented: Binding<Bool>,
        localization: HarvestSeasonPickerLocalization? = nil,
        includesAll: Bool = true,
        onSelect: @escaping (HarvestSeasonSelection) -> Void
    ) {
        self.harvestSeasons = harvestSeasons
        self.includesAll = includesAll
        self.selectedSelection = selectedSelection
        self._isPresented = isPresented
        self.localizationOverride = localization
        self.onSelect = onSelect
    }

    // MARK: - Body
    var body: some View {
        SingleSelectionDropdown(
            items: selections,
            selectedItem: selectedSelection,
            isPresented: $isPresented,
            outlined: !includesAll,
            onSelect: onSelect,
            triggerContent: triggerContent,
            rowContent: rowContent
        )
    }
}

// MARK: - Private Layout
private extension HarvestSeasonPicker {
    func triggerContent(isExpanded: Bool) -> some View {
        HarvestSeasonPickerTrigger(
            title: selectedSelection?.title(using: localization) ?? AppLocale.CreationSeason.choose,
            disclosureTitle: localization.disclosureTitle(isExpanded: isExpanded),
            isExpanded: isExpanded
        )
        .accessibilityLabel(selectedSelection?.accessibleTitle(using: localization) ?? AppLocale.CreationSeason.choose)
    }

    func rowContent(
        selection: HarvestSeasonSelection,
        isSelected: Bool
    ) -> some View {
        HarvestSeasonPickerRow(
            title: selection.title(using: localization),
            status: selection.status,
            isSelected: isSelected,
            localization: localization
        )
        .accessibilityLabel(selection.accessibleTitle(using: localization))
    }
}

// MARK: - HarvestSeasonPickerTrigger
private struct HarvestSeasonPickerTrigger: View {
    let title: String
    let disclosureTitle: String
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            AppAssets.Home.homeCalendarIcon.imageSwiftUI
                .frame(width: 20, height: 20)
                .layoutPriority(1)
                .accessibilityHidden(true)

            Text(title)
                .font(AppFonts.FiraSans.regular.swiftUIFont(size: 14, relativeTo: .body))
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)

            AppAssets.DisclosureGroup.disclosureGroupChevronDown.imageSwiftUI
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(isExpanded ? -180 : 0))
                .layoutPriority(1)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(disclosureTitle)
    }
}

// MARK: - HarvestSeasonPickerRow
private struct HarvestSeasonPickerRow: View {
    let title: String
    let status: HarvestSeasonStatus?
    let isSelected: Bool
    let localization: HarvestSeasonPickerLocalization

    private var statusPresentation: HarvestSeasonStatusPresentation? {
        status.map(localization.statusPresentation)
    }

    private var accessibilityTitle: String {
        guard let statusPresentation else { return title }
        return localization.accessibleRowTitle(
            title: title,
            statusTitle: statusPresentation.title
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppFonts.FiraSans.regular.swiftUIFont(size: 14, relativeTo: .body))
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)

            if let statusPresentation {
                HarvestSeasonStatusBadge(presentation: statusPresentation)
            }

            Spacer(minLength: .zero)

            if isSelected {
                AppAssets.Language.langSelectedAccessory.imageSwiftUI
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }
}

// MARK: - HarvestSeasonStatusBadge
private struct HarvestSeasonStatusBadge: View {
    let presentation: HarvestSeasonStatusPresentation

    var body: some View {
        Text(presentation.title)
            .font(AppFonts.FiraSans.medium.swiftUIFont(size: 12, relativeTo: .caption))
            .foregroundStyle(presentation.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(presentation.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Previews
#if !RELEASE
private enum HarvestSeasonPickerPreviewData {
    static let seasons: [HarvestSeason] = [
        HarvestSeason(
            id: "5D318901-86EB-4707-926B-57455BB9CC84",
            startDate: Date(timeIntervalSince1970: 1_767_225_600),
            endDate: Date(timeIntervalSince1970: 1_798_761_600),
            status: .active
        ),
        HarvestSeason(
            id: "049C2853-217E-4BBC-A5FC-B487D42C317D",
            startDate: Date(timeIntervalSince1970: 1_735_689_600),
            endDate: Date(timeIntervalSince1970: 1_767_225_600),
            status: .past
        ),
        HarvestSeason(
            id: "98193AB8-1F40-4E36-B6A7-1EE898352744",
            startDate: Date(timeIntervalSince1970: 1_704_067_200),
            endDate: Date(timeIntervalSince1970: 1_735_689_600),
            status: .archive
        )
    ]

    static let selections = seasons.map(HarvestSeasonSelection.harvestSeason) + [.all]
    static let english = HarvestSeasonPickerLocalization.preview(language: .english)
    static let french = HarvestSeasonPickerLocalization.preview(language: .french)
    static let spanish = HarvestSeasonPickerLocalization.preview(language: .spanish)
}

private struct HarvestSeasonPickerPreview: View {
    @State private var selectedSelection: HarvestSeasonSelection
    @State private var isPresented: Bool

    private let localization: HarvestSeasonPickerLocalization

    init(
        selectedSelection: HarvestSeasonSelection,
        isPresented: Bool,
        localization: HarvestSeasonPickerLocalization
    ) {
        self._selectedSelection = State(initialValue: selectedSelection)
        self._isPresented = State(initialValue: isPresented)
        self.localization = localization
    }

    var body: some View {
        HarvestSeasonPicker(
            harvestSeasons: HarvestSeasonPickerPreviewData.seasons,
            selectedSelection: selectedSelection,
            isPresented: $isPresented,
            localization: localization,
            onSelect: { selectedSelection = $0 }
        )
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.Gray.gray5.colorSwiftUI)
    }
}

private struct HarvestSeasonPicker_Previews: PreviewProvider {
    private typealias Data = HarvestSeasonPickerPreviewData

    static var previews: some View {
        Group {
            preview(selection: Data.selections[0], localization: Data.english)
                .previewDisplayName("Collapsed Active — English")

            preview(selection: Data.selections[0], isPresented: true, localization: Data.english)
                .previewDisplayName("Expanded Active — English")

            preview(selection: Data.selections[1], isPresented: true, localization: Data.english)
                .previewDisplayName("Selected Past — English")

            preview(selection: Data.selections[2], isPresented: true, localization: Data.english)
                .previewDisplayName("Selected Archived — English")

            preview(selection: Data.selections[3], isPresented: true, localization: Data.english)
                .previewDisplayName("Selected All — English")

            preview(selection: Data.selections[3], isPresented: true, localization: Data.french)
                .previewDisplayName("Long All — French")

            preview(selection: Data.selections[0], isPresented: true, localization: Data.spanish)
                .previewDisplayName("Expanded — Spanish")

            preview(
                selection: Data.selections[0],
                isPresented: true,
                localization: Data.english,
                height: 220
            )
                .previewDisplayName("Constrained Height")
        }
        .previewLayout(.sizeThatFits)
    }

    private static func preview(
        selection: HarvestSeasonSelection,
        isPresented: Bool = false,
        localization: HarvestSeasonPickerLocalization,
        height: CGFloat = 420
    ) -> some View {
        HarvestSeasonPickerPreview(
            selectedSelection: selection,
            isPresented: isPresented,
            localization: localization
        )
        .accessibilityLabel(selection.accessibleTitle(using: localization))
        .frame(width: 390, height: height)
    }
}
#endif
