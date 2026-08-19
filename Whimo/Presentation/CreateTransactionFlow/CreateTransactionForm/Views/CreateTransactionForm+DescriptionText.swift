//
//  CreateTransactionForm+DescriptionText.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 11.06.2025.
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
private typealias DescriptionText = Module.DescriptionText

// MARK: - DescriptionText
extension Module {
    struct DescriptionText: View {
        let row: Row
        let value: String?

        private var titleText: String { value ?? row.placeholder }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CreateTransactionFormDescriptionText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DescriptionText(row: .geodata, value: "Tap to add data")
        }
    }
}
#endif
