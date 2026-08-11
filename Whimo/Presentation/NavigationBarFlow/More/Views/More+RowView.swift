//
//  More+RowView.swift
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
import Resources

private typealias Module = MoreModule
private typealias RowView = Module.RowView

// MARK: - MainView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let row: Row

        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        HStack(spacing: 8) {
            leadingAccessoryImage()
            text()
            if row.enableTrailingIndicator {
                trailingAccessoryImage()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder func leadingAccessoryImage() -> some View {
        row.leadingAccessory
            .frame(width: 24, height: 24)
    }

    @ViewBuilder func text() -> some View {
        Text(row.title)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func trailingAccessoryImage() -> some View {
        AppAssets.Shared.sharedChevronRight.imageSwiftUI
            .frame(width: 24, height: 24)
    }
}

// MARK: - Previews
#if !RELEASE
struct MoreRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RowView(row: .appVersion)
            RowView(row: .legalInformation)
            RowView(row: .logOut)
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
