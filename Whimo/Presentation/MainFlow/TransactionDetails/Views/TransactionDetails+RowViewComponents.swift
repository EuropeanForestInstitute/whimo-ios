//
//  TransactionDetails+RowViewComponents.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 14.05.2025.
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

private typealias Module = TransactionDetailsModule

extension Module {
    // MARK: - RowTitle
    struct RowTitle: View {
        let text: String
        var body: some View {
            Text(text)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
    }

    // MARK: - RowDescription
    struct RowDescription: View {
        let text: String
        let textColor: Color

        init(text: String, textColor: Color = AppColors.Gray.gray90.colorSwiftUI) {
            self.text = text
            self.textColor = textColor
        }

        var body: some View {
            Text(text)
                .appFontRegularSize16()
                .foregroundStyle(textColor)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - RowDescription
    struct RowBoldDescription: View {
        let text: String
        var body: some View {
            Text(text)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - RowDescription
    struct RowStatusDescription: View {
        let status: TransactionModel.Status
        var body: some View {
            Text(status.title)
                .appFontMediumSize16()
                .foregroundStyle(status.titleColor)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(status.backgroundColor)
                }
        }
    }

    // MARK: - TrailingAccessoryImage
    struct TrailingAccessoryImage: View {
        var body: some View {
            AppAssets.Shared.sharedChevronRight.imageSwiftUI
                .frame(width: 20, height: 20)
        }
    }
}
