//
//  SegmentedPicker.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 30.04.2025.
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
import Utility
import Resources
import IdentifiedCollections

// MARK: - SegmentedPicker
public struct SegmentedPicker<Model: DomainModel>: View {
    // MARK: - Public Properties
    public let items: IdentifiedArrayOf<Model>
    public var selection: Binding<Model>
    let title: (Model) -> String
    let icon: (Model) -> UIImage?

    // MARK: - Private Properties
    @AppStorage(.currentLocalize)
    private var currentLocalize: LocalizeKeys = .english
    @Namespace private var selectionDividerNamespace

    // MARK: - Constants
    private let kSelectionDividerHeight: CGFloat = 2

    // MARK: - Init
    public init(
        items: IdentifiedArrayOf<Model>,
        selection: Binding<Model>,
        title: @escaping (Model) -> String,
        icon: @escaping (Model) -> UIImage? = { _ in nil }
    ) {
        self.items = items
        self.selection = selection
        self.title = title
        self.icon = icon
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: .zero) {
            content()
                .padding(.top, 12)
            Divider()
                .overlay(AppColors.Gray.gray10.colorSwiftUI)
        }
        .background {
            AppColors.Other.white.colorSwiftUI
        }
    }
}

// MARK: - Private Layout
private extension SegmentedPicker {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: .zero) {
            ForEach(items, id: \.self) { item in
                VStack(spacing: .zero) {
                    button(item: item)
                        .background(
                            Color.clear
                                .frame(height: kSelectionDividerHeight)
                                .matchedGeometryEffect(
                                    id: item,
                                    in: selectionDividerNamespace,
                                    isSource: true
                                )
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        )
                }
            }
            .background {
                selectionDivider()
                    .matchedGeometryEffect(
                        id: selection.wrappedValue,
                        in: selectionDividerNamespace,
                        isSource: false
                    )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
    }

    @ViewBuilder func button(item: Model) -> some View {
        Button {
            didTapPickerItem(item)
        } label: {
            segmentView(item: item)
        }
    }

    @ViewBuilder func segmentView(item: Model) -> some View {
        VStack(spacing: .zero) {
            HStack(spacing: 4) {
                if let uiImage = icon(item) {
                    Image(uiImage: uiImage)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                Text(title(item))
                    .appFontMediumSize16()
            }
            .foregroundStyle(
                selection.wrappedValue == item
                ? AppColors.Primary.primarySeaBlue.colorSwiftUI
                : AppColors.Gray.gray50.colorSwiftUI
            )
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    @ViewBuilder func selectionDivider() -> some View {
        Rectangle()
            .fill(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            .frame(height: kSelectionDividerHeight)
    }
}

// MARK: - Private Methods
private extension SegmentedPicker {
    func didTapPickerItem(_ item: Model) {
        withAnimation(.spring(duration: 0.23)) {
            selection.wrappedValue = item
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct SegmentedPicker_Previews: PreviewProvider {
    private struct TestModel: DomainModel {
        let title: String
        let icon: UIImage?

        init(title: String, icon: UIImage? = nil) {
            self.title = title
            self.icon = icon
        }

        var id: Self { self }
    }

    struct Container: View {
        private let items: IdentifiedArrayOf<TestModel> = .init(uniqueElements: [
            TestModel(title: "Log in Log in"),
            TestModel(title: "Register Register Register Register"),
            TestModel(title: "Test Test Test Test Test Test Test Test")
        ])
        @State private var selection: TestModel = .init(title: "Log in Log in")

        var body: some View {
            SegmentedPicker(
                items: items,
                selection: $selection,
                title: { $0.title },
                icon: { $0.icon }
            )
        }
    }

    static var previews: some View {
        VStack {
            Container()

            SegmentedPicker(
                items: .init(uniqueElements: [
                    .init(title: "Log in with email"),
                    .init(title: "Log in")
                ]),
                selection: .constant(TestModel(title: "Log in with email")),
                title: { $0.title }
            )

            SegmentedPicker(
                items: .init(uniqueElements: [
                    .init(title: "All", icon: AppAssets.TabBar.tabbarHome.image),
                    .init(title: "Bought", icon: AppAssets.Transactions.transactionsBuyIcon.image),
                    .init(title: "Sold", icon: AppAssets.Transactions.transactionsSellIcon.image)
                ]),
                selection: .constant(TestModel(title: "All", icon: AppAssets.TabBar.tabbarHome.image)),
                title: { $0.title },
                icon: { $0.icon }
            )
        }
        .frame(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        .background(.red.opacity(0.5))
    }
}
#endif
