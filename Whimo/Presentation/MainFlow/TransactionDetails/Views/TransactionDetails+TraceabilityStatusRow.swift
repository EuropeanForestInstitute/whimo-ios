//
//  TransactionDetails+TraceabilityStatusRow.swift
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
private typealias TraceabilityStatusRow = Module.TraceabilityStatusRow
private typealias Localization = AppLocale.TransactionDetails.Row.TraceabilityStatus

// MARK: - TraceabilityStatusRow
extension Module {
    struct TraceabilityStatusRow: View {
        // MARK: - Properties
        let title: String
        let traceabilityStatus: TransactionModel.Traceability

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension TraceabilityStatusRow {
    @ViewBuilder func content() -> some View {
        HStack {
            Module.RowTitle(text: title)
            Spacer()
            HStack {
                Text(traceabilityStatus.fullTitle)
                    .appFontMediumSize14()
                    .foregroundStyle(traceabilityStatus.primaryColor)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(traceabilityStatus.secondaryColor)
                    }
                Module.TrailingAccessoryImage()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.Other.white.colorSwiftUI)
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsTraceabilityStatusRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TraceabilityStatusRow(title: "Traceability status", traceabilityStatus: .fullTraceability)
            TraceabilityStatusRow(title: "Traceability status", traceabilityStatus: .partialTraceability)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
