//
//  BuyTxSelectSeller+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 10.06.2025.
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

private typealias Module = BuyTxSelectSellerModule
private typealias RowView = Module.RowView
private typealias Localization = AppLocale.BuyTxSelectSeller

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
                .dashedBackground()
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 12) {
            Spacer()
            accessoryImage()
            text()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            Spacer()
        }
    }

    @ViewBuilder func accessoryImage() -> some View {
        Circle()
            .fill(AppColors.Other.lightBlue.colorSwiftUI)
            .frame(width: 48, height: 48)
            .overlay { row.icon }
    }

    @ViewBuilder func text() -> some View {
        VStack(spacing: 8) {
            Text(row.title)
                .appFontMediumSize18()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Text(row.subtitle)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct BuyTxSelectSellerRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                RowView(row: .farmer)
                RowView(row: .cooperative)
            }
            .padding()
        }
        .background(.red.opacity(0.5))
    }
}
#endif
