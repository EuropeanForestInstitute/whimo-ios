//
//  View+TextAppearance.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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

extension View {
    // MARK: - Regular
    public func appFontRegularSize12() -> some View {
        self.font(FontBuilder.buildRegular(size: 12))
    }

    public func appFontRegularSize14() -> some View {
        self.font(FontBuilder.buildRegular(size: 14))
    }

    public func appFontRegularSize16() -> some View {
        self.font(FontBuilder.buildRegular(size: 16))
    }

    public func appFontRegularSize18() -> some View {
        self.font(FontBuilder.buildRegular(size: 18))
    }

    // MARK: - Medium
    public func appFontMediumSize12() -> some View {
        self.font(FontBuilder.buildMedium(size: 12))
    }

    public func appFontMediumSize14() -> some View {
        self.font(FontBuilder.buildMedium(size: 14))
    }

    public func appFontMediumSize16() -> some View {
        self.font(FontBuilder.buildMedium(size: 16))
    }

    public func appFontMediumSize18() -> some View {
        self.font(FontBuilder.buildMedium(size: 18))
    }

    // MARK: - Semibold
    public func appFontSemiboldSize22() -> some View {
        self.font(FontBuilder.buildSemibold(size: 22))
    }

    public func appFontSemiboldSize28() -> some View {
        self.font(FontBuilder.buildSemibold(size: 28))
    }
}
