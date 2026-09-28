//
//  KeyboardDefaultToolbar.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 08.05.2025.
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

private typealias Localization = AppLocale.General.Keyboard

// MARK: - KeyboardDefaultToolbar
public struct KeyboardDefaultToolbar: ViewModifier {
    let action: () -> Void

    public func body(content: Content) -> some View {
        content
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(Localization.Toolbar.done, role: .cancel, action: action)
                            .appFontMediumSize16()
                            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                    }
                } else {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button(Localization.Toolbar.done, role: .cancel, action: action)
                                .appFontMediumSize16()
                                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                        }
                    }
                }
            }
    }
}

// MARK: - View+KeyboardDefaultToolbar
extension View {
    public func keyboardDefaultToolbar(action: @escaping () -> Void) -> some View {
        modifier(KeyboardDefaultToolbar(action: action))
    }

    public func keyboardDefaultToolbar(action: @autoclosure @escaping () -> Void) -> some View {
        modifier(KeyboardDefaultToolbar(action: action))
    }
}
