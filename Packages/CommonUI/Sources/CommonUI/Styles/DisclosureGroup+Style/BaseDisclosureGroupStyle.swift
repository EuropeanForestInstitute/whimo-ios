//
//  BaseDisclosureGroupStyle.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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
import Resources

private typealias Assets = AppAssets.DisclosureGroup

// MARK: - BaseDisclosureGroupStyle
public struct BaseDisclosureGroupStyle: DisclosureGroupStyle {
    public struct Appearance {
        let font: Font
        let textColor: Color
        let backgroundColor: Color
        let indicatorColor: Color?
    }

    // MARK: - Properties
    let appearance: Appearance

    // MARK: - Init
    public init(appearance: Appearance) {
        self.appearance = appearance
    }

    // MARK: - Body
    public func makeBody(configuration: Configuration) -> some View {
        content(configuration: configuration)
    }
}

// MARK: - Private Layout
private extension BaseDisclosureGroupStyle {
    @ViewBuilder func content(configuration: Configuration) -> some View {
        VStack(spacing: .zero) {
            buttonLabel(configuration: configuration)
            expandableContent(configuration: configuration)
        }
    }

    @ViewBuilder func buttonLabel(configuration: Configuration) -> some View {
        Button {
            withAnimation {
                configuration.isExpanded.toggle()
            }
        } label: {
            label(configuration: configuration)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background { appearance.backgroundColor }
    }

    @ViewBuilder func label(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(appearance.font)
                .foregroundStyle(appearance.textColor)
            Spacer()
            disclosureIndicator()
                .rotationEffect(.degrees(configuration.isExpanded ? -180 : 0))
        }
    }

    @ViewBuilder func disclosureIndicator() -> some View {
        if let indicatorColor = appearance.indicatorColor {
            Assets.disclosureGroupChevronDown.imageSwiftUI
                .renderingMode(.template)
                .tint(indicatorColor)
        } else {
            Assets.disclosureGroupChevronDown.imageSwiftUI
        }
    }

    @ViewBuilder func expandableContent(configuration: Configuration) -> some View {
        if configuration.isExpanded {
            configuration.content
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct BaseDisclosureGroupStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            DisclosureGroup {
                Text("Content")
            } label: {
                Text("Label")
            }
            .background(.white)

            DisclosureGroup {
                Text("Content")
            } label: {
                Text("Label")
            }
            .disclosureGroupStyle(BaseDisclosureGroupStyle(appearance: .init(
                font: FontBuilder.buildRegular(size: 14),
                textColor: AppColors.Gray.gray90.colorSwiftUI,
                backgroundColor: AppColors.Gray.gray5.colorSwiftUI,
                indicatorColor: nil
            )))

            DisclosureGroup {
                Text("Content")
            } label: {
                Text("Label")
            }
            .disclosureGroupStyle(BaseDisclosureGroupStyle(appearance: .init(
                font: FontBuilder.buildMedium(size: 16),
                textColor: AppColors.Primary.primarySeaBlue.colorSwiftUI,
                backgroundColor: AppColors.Other.lightBlue.colorSwiftUI,
                indicatorColor: AppColors.Primary.primarySeaBlue.colorSwiftUI
            )))
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDevice(.iPhone15Pro)
    }
}
#endif
