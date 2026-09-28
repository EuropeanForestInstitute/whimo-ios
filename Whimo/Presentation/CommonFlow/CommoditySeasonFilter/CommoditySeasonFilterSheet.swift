//
//  CommoditySeasonFilterSheet.swift
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

private typealias Localization = AppLocale.CommoditySeasonFilter

struct CommoditySeasonFilterSheet: View {
    @ObservedObject var viewModel: CommoditySeasonFilterViewModel
    let maximumHeight: CGFloat
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 100
    @State private var headerHeight: CGFloat = 72
    @State private var footerHeight: CGFloat = 80
    @State private var expandedSection: Section?
    private let titleSize: CGFloat = 18

    private enum Section { case group, season }

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.title)
                .font(FontBuilder.buildMedium(size: titleSize))
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            ScrollView {
                sections
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .frame(height: min(contentHeight, max(48, maximumHeight - headerHeight - footerHeight)))
            footer
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
        }
        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
        .selfSizedSheet(defaultHeight: 252)
        .presentationCornerRadius(24)
        .presentationBackground(AppColors.Other.white.colorSwiftUI)
        .accessibilityAction(.escape) { dismiss() }
        .task { await viewModel.load() }
        .task(id: viewModel.draft.group?.id) { await viewModel.loadSeasons() }
        .onDisappear { viewModel.cancelLoading() }
    }

    private var sections: some View {
        VStack(spacing: 2) {
            SingleChoiceFilterSection(
                selection: viewModel.draft.group?.name ?? Localization.allGroups,
                allTitle: Localization.allGroups, items: viewModel.groups,
                selectedId: viewModel.draft.group?.id, titleForItem: { $0.name },
                accessibilityTitleForItem: { $0.name }, isExpanded: expansion(for: .group),
                isEnabled: true, onSelect: viewModel.selectGroup
            )
            catalogueState(loading: viewModel.groupsLoading, failed: viewModel.groupsFailed,
                           cached: viewModel.groupsCached) { Task { await viewModel.loadGroups() } }
            SingleChoiceFilterSection(
                selection: viewModel.draft.season?.name ?? Localization.allSeasons,
                allTitle: Localization.allSeasons, items: viewModel.seasons,
                selectedId: viewModel.draft.season?.id, titleForItem: { $0.name },
                accessibilityTitleForItem: seasonAccessibilityTitle, isExpanded: expansion(for: .season),
                isEnabled: viewModel.draft.group != nil, onSelect: viewModel.selectSeason
            )
            .accessibilityHint(viewModel.draft.group == nil ? Localization.chooseGroup : "")
            if viewModel.draft.group != nil {
                catalogueState(loading: viewModel.seasonsLoading, failed: viewModel.seasonsFailed,
                               cached: viewModel.seasonsCached) { Task { await viewModel.loadSeasons() } }
                if !viewModel.seasonsLoading && !viewModel.seasonsFailed && viewModel.seasons.isEmpty {
                    Text(Localization.noSeasons).font(.footnote).padding(16)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            FilterActionButton(title: Localization.reset, isProminent: false,
                               isEnabled: viewModel.canReset, action: viewModel.reset)
            FilterActionButton(title: Localization.apply, isProminent: true,
                               isEnabled: viewModel.canApply, action: viewModel.apply)
        }
        .padding(16)
    }

    private func expansion(for section: Section) -> Binding<Bool> {
        Binding(get: { expandedSection == section }, set: { expandedSection = $0 ? section : nil })
    }

    @ViewBuilder
    private func catalogueState(loading: Bool, failed: Bool, cached: Bool, retry: @escaping () -> Void) -> some View {
        if loading { ProgressView().padding(12).accessibilityLabel(Localization.loading) }
        if failed {
            VStack {
                Text(Localization.catalogueError)
                Button(Localization.retry, action: retry)
            }
            .padding(16)
        }
        if cached { Text(Localization.cachedCatalogue).font(.footnote).padding(12) }
    }

    private func seasonAccessibilityTitle(_ season: HarvestSeason) -> String {
        let status: String
        switch season.status {
            case .active: status = AppLocale.HarvestSeasonPicker.Status.active
            case .past: status = AppLocale.HarvestSeasonPicker.Status.past
            case .archive: status = AppLocale.HarvestSeasonPicker.Status.archived
        }
        return season.name + ", " + status
    }
}

private struct SingleChoiceFilterSection<Item: Identifiable>: View where Item.ID == String {
    let selection: String
    let allTitle: String
    let items: [Item]
    let selectedId: String?
    let titleForItem: (Item) -> String
    let accessibilityTitleForItem: (Item) -> String
    @Binding var isExpanded: Bool
    let isEnabled: Bool
    let onSelect: (Item?) -> Void
    private let rowFontSize: CGFloat = 14
    private let summaryFontSize: CGFloat = 16

    private var showsItems: Bool { isExpanded && isEnabled }

    var body: some View {
        VStack(spacing: 0) {
            Button { isExpanded.toggle() } label: {
                HStack(spacing: 16) {
                    Text(selection)
                        .font(showsItems ? FontBuilder.buildMedium(size: summaryFontSize)
                              : FontBuilder.buildRegular(size: summaryFontSize))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: showsItems ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(showsItems ? AppColors.Primary.primarySeaBlue.colorSwiftUI
                                         : AppColors.Gray.gray40.colorSwiftUI)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 48)
                .background(showsItems ? AppColors.Primary.primarySeaBlue.colorSwiftUI.opacity(0.08)
                            : AppColors.Gray.gray5.colorSwiftUI)
                .contentShape(Rectangle())
            }
            .buttonStyle(FilterControlStyle())
            .foregroundStyle(summaryColor)
            .disabled(!isEnabled)
            .accessibilityValue(showsItems ? AppLocale.HarvestSeasonPicker.Disclosure.expanded
                                : AppLocale.HarvestSeasonPicker.Disclosure.collapsed)
            if showsItems {
                VStack(spacing: 0) {
                    row(title: allTitle, accessibilityTitle: allTitle, selected: selectedId == nil) { onSelect(nil) }
                    ForEach(items) { item in
                        DashDivider()
                        row(title: titleForItem(item), accessibilityTitle: accessibilityTitleForItem(item),
                            selected: selectedId == item.id) { onSelect(item) }
                    }
                }
            }
        }
    }

    private var summaryColor: Color {
        if !isEnabled { return AppColors.Gray.gray40.colorSwiftUI }
        return showsItems ? AppColors.Primary.primarySeaBlue.colorSwiftUI : AppColors.Gray.gray90.colorSwiftUI
    }

    private func row(title: String, accessibilityTitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(title)
                    .font(FontBuilder.buildRegular(size: rowFontSize))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if selected {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(AppColors.Expanded.expandedSuccess.colorSwiftUI)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(FilterControlStyle())
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct FilterActionButton: View {
    let title: String
    let isProminent: Bool
    let isEnabled: Bool
    let action: () -> Void
    private let fontSize: CGFloat = 16

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FontBuilder.buildMedium(size: fontSize))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(isProminent ? AppColors.Other.white.colorSwiftUI
                                 : isEnabled ? AppColors.Gray.gray90.colorSwiftUI : AppColors.Gray.gray40.colorSwiftUI)
                .background(isProminent ? AppColors.Primary.primarySeaBlue.colorSwiftUI.opacity(isEnabled ? 1 : 0.5)
                            : AppColors.Other.white.colorSwiftUI, in: .rect(cornerRadius: 8))
                .overlay {
                    if !isProminent {
                        RoundedRectangle(cornerRadius: 8).strokeBorder(AppColors.Gray.gray10.colorSwiftUI, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(FilterControlStyle())
        .disabled(!isEnabled)
    }
}

private struct FilterControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
    }
}
