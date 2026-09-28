//
//  SingleSelectionDropdown.swift
//  CommonUI
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
import WindowOverlay
import Resources

// MARK: - SingleSelectionDropdown
/// A controlled, anchored dropdown for choosing one value from a fixed collection.
///
/// The dropdown owns trigger and row buttons, presentation and dismissal mechanics,
/// positioning, containment, and changed-selection delivery. The trigger builder
/// receives the current disclosure state, while the row builder receives each row's
/// selection state so callers can provide feature-specific visuals and accessibility
/// descriptions.
///
/// - Important: `items` must not be empty, and `selectedItem` must be present in
///   `items` when non-nil. Selection is intentionally reported only through `onSelect`; callers
///   retain ownership of the selected value and must not expect a repeated selection
///   callback.
public struct SingleSelectionDropdown<Item, TriggerContent, RowContent>: View
where Item: Identifiable & Equatable, TriggerContent: View, RowContent: View {
    // MARK: - Private Properties
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isPresented: Bool
    @State private var triggerFrame: CGRect = .zero

    private let outlined: Bool
    private let items: [Item]
    private let selectedItem: Item?
    private let onSelect: (Item) -> Void
    private let triggerContent: (Bool) -> TriggerContent
    private let rowContent: (Item, Bool) -> RowContent

    private var disclosureAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: Metrics.animationDuration)
    }

    // MARK: - Public Init
    /// Creates a controlled single-selection dropdown.
    ///
    /// - Parameters:
    ///   - items: A non-empty collection with stable identity.
    ///   - selectedItem: The current selection, or nil until a user chooses; a non-nil value must occur in `items`.
    ///   - isPresented: The caller-owned transient disclosure state.
    ///   - onSelect: Called once only when a row differs from `selectedItem`.
    ///   - triggerContent: Inner trigger content and the current disclosure state.
    ///   - rowContent: Inner row content, its item, and whether it is selected.
    public init(
        items: [Item],
        selectedItem: Item?,
        isPresented: Binding<Bool>,
        outlined: Bool = false,
        onSelect: @escaping (Item) -> Void,
        @ViewBuilder triggerContent: @escaping (Bool) -> TriggerContent,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        precondition(!items.isEmpty, "SingleSelectionDropdown requires at least one item.")
        precondition(
            selectedItem == nil || items.contains(where: { $0 == selectedItem }),
            "SingleSelectionDropdown requires selectedItem to be present in items."
        )

        self.outlined = outlined
        self.items = items
        self.selectedItem = selectedItem
        self._isPresented = isPresented
        self.onSelect = onSelect
        self.triggerContent = triggerContent
        self.rowContent = rowContent
    }

    // MARK: - Body
    public var body: some View {
        Button(action: togglePresentation) {
            triggerContent(isPresented)
                .singleSelectionDropdownContent()
        }
        .buttonStyle(.plain)
        .background {
            if outlined {
                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                    .fill(AppColors.Other.white.colorSwiftUI)
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                            .stroke(AppColors.Gray.gray20.colorSwiftUI, lineWidth: 1)
                    }
            } else {
                BackgroundShadowView(style: .card)
            }
        }
        .onGeometryChange(
            for: CGRect.self,
            of: { proxy in proxy.frame(in: .global) },
            action: updateTriggerFrame
        )
        .animation(disclosureAnimation, value: isPresented)
        .background {
            Color.clear
                .windowOverlay(isPresented: isPresented) {
                    SingleSelectionDropdownOverlay(
                        items: items,
                        selectedItem: selectedItem,
                        isPresented: $isPresented,
                        triggerFrame: triggerFrame,
                        onSelect: onSelect,
                        rowContent: rowContent
                    )
                }
        }
    }
}

// MARK: - Private Methods
private extension SingleSelectionDropdown {
    func togglePresentation() {
        guard triggerFrame != .zero else { return }

        withAnimation(disclosureAnimation) {
            isPresented.toggle()
        }
    }

    func updateTriggerFrame(_ newFrame: CGRect) {
        guard newFrame != triggerFrame else { return }

        if triggerFrame != .zero, isPresented {
            withAnimation(disclosureAnimation) {
                isPresented = false
            }
        }

        triggerFrame = newFrame
    }
}

// MARK: - SingleSelectionDropdownOverlay
private struct SingleSelectionDropdownOverlay<Item, RowContent>: View
where Item: Identifiable & Equatable, RowContent: View {
    // MARK: - Private Properties
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isPresented: Bool
    @State private var containerFrame: CGRect = .zero
    @State private var isCardVisible = false

    private let items: [Item]
    private let selectedItem: Item?
    private let triggerFrame: CGRect
    private let onSelect: (Item) -> Void
    private let rowContent: (Item, Bool) -> RowContent

    private var disclosureAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: Metrics.animationDuration)
    }

    // MARK: - Init
    init(
        items: [Item],
        selectedItem: Item?,
        isPresented: Binding<Bool>,
        triggerFrame: CGRect,
        onSelect: @escaping (Item) -> Void,
        rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self._isPresented = isPresented
        self.triggerFrame = triggerFrame
        self.onSelect = onSelect
        self.rowContent = rowContent
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)

            ZStack(alignment: .topLeading) {
                outsideDismissalArea
                dropdownCard(availableHeight: availableHeight(in: frame))
                    .offset(
                        x: triggerFrame.minX - frame.minX,
                        y: triggerFrame.maxY + Metrics.triggerGap - frame.minY
                    )
                    .opacity(isCardVisible ? 1 : 0)
                    .scaleEffect(
                        isCardVisible ? 1 : Metrics.hiddenCardScale,
                        anchor: .top
                    )
            }
            .onAppear {
                containerFrame = frame
                withAnimation(disclosureAnimation) {
                    isCardVisible = true
                }
            }
            .onChange(of: frame) { newFrame in
                handleContainerFrameChange(newFrame)
            }
        }
    }
}

// MARK: - Private Layout
private extension SingleSelectionDropdownOverlay {
    var outsideDismissalArea: some View {
        Button(action: dismiss) {
            Color.black
                .opacity(Metrics.hitTestingOpacity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { _ in dismiss() }
        )
    }

    func dropdownCard(availableHeight: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: .zero) {
                ForEach(items) { item in
                    VStack(spacing: .zero) {
                        rowButton(for: item)

                        if item.id != items.last?.id {
                            AppColors.Gray.gray5.colorSwiftUI
                                .frame(height: Metrics.separatorHeight)
                        }
                    }
                }
            }
        }
        .frame(
            width: triggerFrame.width,
            height: cardHeight(availableHeight: availableHeight)
        )
        .background(AppColors.Other.white.colorSwiftUI)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
        .background {
            BackgroundShadowView(style: .card)
        }
    }

    func rowButton(for item: Item) -> some View {
        let isSelected = item == selectedItem

        return Button {
            select(item)
        } label: {
            rowContent(item, isSelected)
                .singleSelectionDropdownContent()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Private Methods
private extension SingleSelectionDropdownOverlay {
    func availableHeight(in containerFrame: CGRect) -> CGFloat {
        max(
            .zero,
            containerFrame.maxY - triggerFrame.maxY - Metrics.triggerGap
        )
    }

    func cardHeight(availableHeight: CGFloat) -> CGFloat {
        let rowsHeight = CGFloat(items.count) * Metrics.contentHeight
        let separatorsHeight = CGFloat(max(items.count - 1, .zero)) * Metrics.separatorHeight

        return min(rowsHeight + separatorsHeight, availableHeight)
    }

    func select(_ item: Item) {
        dismiss()

        if item != selectedItem {
            onSelect(item)
        }
    }

    func dismiss() {
        withAnimation(disclosureAnimation) {
            isCardVisible = false
            isPresented = false
        }
    }

    func handleContainerFrameChange(_ newFrame: CGRect) {
        guard newFrame != containerFrame else { return }

        if containerFrame != .zero {
            dismiss()
        }

        containerFrame = newFrame
    }
}

private struct SingleSelectionDropdownContentModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.contentHeight)
            .contentShape(Rectangle())
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

private extension View {
    func singleSelectionDropdownContent() -> some View {
        modifier(SingleSelectionDropdownContentModifier())
    }
}

private enum Metrics {
    static let animationDuration: TimeInterval = 0.2
    static let cardCornerRadius: CGFloat = 8
    static let contentHeight: CGFloat = 48
    static let hiddenCardScale: CGFloat = 0.98
    static let hitTestingOpacity: CGFloat = 0.011
    static let separatorHeight: CGFloat = 2
    static let triggerGap: CGFloat = 4
}

// MARK: - Previews
#if !RELEASE
private struct SingleSelectionDropdownPreviewItem: Identifiable, Equatable {
    let id: Int
    let title: String
}

private struct SingleSelectionDropdownPreview: View {
    @State private var selectedItem: SingleSelectionDropdownPreviewItem
    @State private var isPresented: Bool

    private let items: [SingleSelectionDropdownPreviewItem]

    init(
        items: [SingleSelectionDropdownPreviewItem],
        selectedItem: SingleSelectionDropdownPreviewItem,
        isPresented: Bool
    ) {
        self.items = items
        self._selectedItem = State(initialValue: selectedItem)
        self._isPresented = State(initialValue: isPresented)
    }

    var body: some View {
        SingleSelectionDropdown(
            items: items,
            selectedItem: selectedItem,
            isPresented: $isPresented,
            onSelect: { selectedItem = $0 },
            triggerContent: { isExpanded in
                HStack(spacing: 8) {
                    Text(selectedItem.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .accessibilityLabel(selectedItem.title)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            },
            rowContent: { item, isSelected in
                HStack(spacing: 8) {
                    Text(item.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 16)
                .accessibilityLabel(item.title)
            }
        )
        .padding(16)
    }
}

private struct SingleSelectionDropdown_Previews: PreviewProvider {
    private static let items: [SingleSelectionDropdownPreviewItem] = [
        .init(id: 1, title: "Current option"),
        .init(id: 2, title: "Previous option"),
        .init(id: 3, title: "Archived option"),
        .init(id: 4, title: "All options")
    ]

    private static let longItems: [SingleSelectionDropdownPreviewItem] = [
        .init(id: 1, title: "An intentionally long localized option that must truncate"),
        .init(id: 2, title: "Another option")
    ]

    static var previews: some View {
        Group {
            SingleSelectionDropdownPreview(
                items: items,
                selectedItem: items[0],
                isPresented: false
            )
            .previewDisplayName("Closed")

            SingleSelectionDropdownPreview(
                items: items,
                selectedItem: items[0],
                isPresented: true
            )
            .previewDisplayName("Open")

            SingleSelectionDropdownPreview(
                items: items,
                selectedItem: items[1],
                isPresented: false
            )
            .previewDisplayName("Changed selection")

            SingleSelectionDropdownPreview(
                items: items,
                selectedItem: items[1],
                isPresented: true
            )
            .previewDisplayName("Repeated selection")

            SingleSelectionDropdownPreview(
                items: longItems,
                selectedItem: longItems[0],
                isPresented: true
            )
            .previewDisplayName("Long content")

            VStack(spacing: .zero) {
                Spacer()

                SingleSelectionDropdownPreview(
                    items: items,
                    selectedItem: items[0],
                    isPresented: true
                )
                .padding(.bottom, 32)
            }
            .previewDisplayName("Constrained height")
        }
    }
}
#endif
