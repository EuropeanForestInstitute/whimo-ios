//
//  ConvertCommodity+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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

private typealias Module = ConvertCommodityListModule
private typealias RowView = Module.RowView

// MARK: - MainView
extension Module {
    struct RowView: View {
        let model: ConvertTypeModel

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
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text(model.name)
                    .appFontMediumSize18()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                Text(model.infoText)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityListRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RowView(model: .decaffeinate)
            RowView(model: .roastCoffe)
            RowView(model: .longType)
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
