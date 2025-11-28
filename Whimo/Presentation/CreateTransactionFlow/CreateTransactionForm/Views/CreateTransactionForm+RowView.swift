//
//  CreateTransactionForm+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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

private typealias Module = CreateTransactionFormModule
private typealias RowView = Module.RowView

// MARK: - RowView
extension Module {
    struct RowView<Content: View>: View {
        // MARK: - Properties
        let row: Row
        let content: () -> Content

        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        // MARK: - Body
        var body: some View {
            makeContent()
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func makeContent() -> some View {
        HStack(alignment: .top, spacing: 8) {
            leadingAccessoryImage()
            text()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailingAccessoryImage()
        }
        .padding()
    }

    @ViewBuilder func leadingAccessoryImage() -> some View {
        row.leadingAccessory
            .frame(width: 24, height: 24)
    }

    @ViewBuilder func text() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
            content()
        }
    }

    @ViewBuilder func trailingAccessoryImage() -> some View {
        AppAssets.Shared.sharedChevronRight.imageSwiftUI
            .frame(width: 24, height: 24)
    }
}

// MARK: - Previews
#if !RELEASE
struct CreateTransactionFormRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RowView(row: .geodata) {
                Module.DescriptionText(row: .geodata, value: "Tap to add data")
            }
            RowView(row: .commodity) {
                Module.DescriptionText(row: .commodity, value: "Tap to add data")
            }
            RowView(row: .volume) {
                Module.DescriptionText(row: .volume, value: "Tap to add data")
            }
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
