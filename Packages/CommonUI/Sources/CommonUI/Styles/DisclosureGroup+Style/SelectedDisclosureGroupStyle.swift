//
//  SelectedDisclosureGroupStyle.swift
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

extension BaseDisclosureGroupStyle.Appearance {
    public static let selected: Self = .init(
        font: FontBuilder.buildMedium(size: 16),
        textColor: AppColors.Primary.primarySeaBlue.colorSwiftUI,
        backgroundColor: AppColors.Other.lightBlue.colorSwiftUI,
        indicatorColor: AppColors.Primary.primarySeaBlue.colorSwiftUI
    )
}

// MARK: - View+SelectedDisclosureGroupStyle
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DisclosureGroup {
    public func applySelectedAppearance() -> some View {
        disclosureGroupStyle(BaseDisclosureGroupStyle(appearance: .selected))
    }
}

// MARK: - Previews
#if !RELEASE
struct SelectedDisclosureGroupStyle_Previews: PreviewProvider {
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
            .applySelectedAppearance()
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDevice(.iPhone15Pro)
    }
}
#endif
