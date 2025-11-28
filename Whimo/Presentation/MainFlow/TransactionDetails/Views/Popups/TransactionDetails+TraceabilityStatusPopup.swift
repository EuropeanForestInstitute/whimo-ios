//
//  TransactionDetails+TraceabilityStatusPopup.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.05.2025.
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
private typealias TraceabilityStatusPopup = Module.TraceabilityStatusPopup
private typealias Localization = AppLocale.TransactionDetails.Popups.TraceabilityStatus

// MARK: - TraceabilityStatusPopup
extension Module {
    struct TraceabilityStatusPopup: View {
        // MARK: - Body
        var body: some View {
            content()
                .fitToScrollView()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Gray.gray5.colorSwiftUI)
                }
        }
    }
}

// MARK: - Private Layout
private extension TraceabilityStatusPopup {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 2) {
            Group {
                textBlock(status: .fullTraceability, description: Localization.Part1.description)
                textBlock(status: .conditionalTraceability, description: Localization.Part2.description)
                textBlock(status: .partialTraceability, description: Localization.Part3.description)
                textBlock(status: .incompleteTraceability, description: Localization.Part4.description)
            }
            .padding(16)
            .background(AppColors.Other.white.colorSwiftUI)
        }
    }

    @ViewBuilder func descriptionText(text: String) -> some View {
        Text(text)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }

    @ViewBuilder func textBlock(status: TransactionModel.Traceability, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status.fullTitle)
                .appFontMediumSize14()
                .foregroundStyle(status.primaryColor)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(status.secondaryColor)
                }
            descriptionText(text: description)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsTraceabilityStatusPopup_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TraceabilityStatusPopup()
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.5))
    }
}
#endif
