//
//  DynamicDisclosureGroupStyle.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 21.05.2025.
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

// MARK: - BaseDisclosureGroupStyle
public struct DynamicDisclosureGroup<Content: View, Label: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label

    // MARK: - Private Properties
    @State private var isExpanded: Bool = false

    private var disclosureStyleAppearance: BaseDisclosureGroupStyle.Appearance {
        isExpanded ? .selected : .default
    }

    // MARK: - Public Init
    public init(content: @escaping () -> Content, label: @escaping () -> Label) {
        self.content = content
        self.label = label
    }

    // MARK: - Body
    public var body: some View {
        makeBody()
    }
}

// MARK: - Private Layout
private extension DynamicDisclosureGroup {
    @ViewBuilder func makeBody() -> some View {
        DisclosureGroup(isExpanded: $isExpanded, content: content, label: label)
            .disclosureGroupStyle(BaseDisclosureGroupStyle(appearance: disclosureStyleAppearance))
            .drawingGroup()
            .animation(.snappy(duration: 0.23), value: isExpanded)
    }
}

// MARK: - Previews
#if !RELEASE
struct DynamicDisclosureGroup_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            DisclosureGroup {
                Text("Content")
            } label: {
                Text("Label")
            }
            .background(.white)

            DynamicDisclosureGroup {
                Text("Content")
            } label: {
                Text("Label")
            }
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDevice(.iPhone15Pro)
    }
}
#endif
