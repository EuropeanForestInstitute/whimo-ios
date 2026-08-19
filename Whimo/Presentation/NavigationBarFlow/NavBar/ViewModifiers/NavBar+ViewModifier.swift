//
//  NavBar+ViewModifier.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

private typealias Module = NavBarModule

extension Module {
    // MARK: - NavBarModifier
    struct NavBarModifier: ViewModifier {
        let title: String
        let titlePrefferedFontStyle: NavBarModule.TitleFontStyle
        let trailingItem: NavBarModule.TrailingItem?
        let showBackButton: Bool
        let enableDivider: Bool

        func body(content: Content) -> some View {
            VStack(spacing: .zero) {
                NavBarModule.assemble(
                    title: title,
                    titlePrefferedFontStyle: titlePrefferedFontStyle,
                    trailingItem: trailingItem,
                    showBackButton: showBackButton
                )
                if enableDivider {
                    DefaultDivider()
                }
                content
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - View+NavBarModifier
extension View {
    func applyNavigationBar(
        title: String,
        titlePrefferedFontStyle: NavBarModule.TitleFontStyle = .h1,
        trailingItem: NavBarModule.TrailingItem? = nil,
        showBackButton: Bool = true,
        enableDivider: Bool = true
    ) -> some View {
        modifier(NavBarModule.NavBarModifier(
            title: title,
            titlePrefferedFontStyle: titlePrefferedFontStyle,
            trailingItem: trailingItem,
            showBackButton: showBackButton,
            enableDivider: enableDivider
        ))
    }
}
