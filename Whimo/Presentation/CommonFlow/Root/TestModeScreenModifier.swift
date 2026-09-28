//
//  TestModeScreenModifier.swift
//  Whimo
//
//  Created on 15.09.2026.
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
import CommonUI
import Resources
import Utility

extension EnvironmentValues {
    @Entry var showsTestModeIndicator = false
}

/// Content chrome shared by navigation and screens without navigation controls.
struct TestModeScreenModifier: ViewModifier {
    let isEnabled: Bool
    var showsOfflineBanner = false

    func body(content: Content) -> some View {
        VStack(spacing: .zero) {
            if isEnabled {
                TestModeLabel()
            }
            if showsOfflineBanner {
                OfflineBanner()
                    .padding(16)
                    .background(AppColors.Other.white.colorSwiftUI)
            }
            content
                .frame(maxWidth: isEnabled ? .infinity : nil,
                       maxHeight: isEnabled ? .infinity : nil, alignment: .top)
                .overlay {
                    if isEnabled {
                        Rectangle()
                            .strokeBorder(AppColors.TestMode.border.colorSwiftUI, lineWidth: 2)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        }
        // Nested navigation and content-owned presentations do not repeat screen chrome.
        .environment(\.showsTestModeIndicator, false)
        .environment(\.showsOfflineBanner, false)
    }
}

struct TestModeLabel: View {
    @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english

    var body: some View {
        Text(AppLocale.TestMode.screenIndicator)
            .font(FontBuilder.buildRegular(size: 12))
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(AppColors.TestMode.background.colorSwiftUI)
            .environment(\.locale, currentLocalize.locale)
            .accessibilityIdentifier("testModeIndicator")
    }
}
