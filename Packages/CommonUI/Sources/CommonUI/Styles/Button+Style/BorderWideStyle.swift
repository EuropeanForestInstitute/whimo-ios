//
//  BorderWideStyle.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 29.04.2025.
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

// MARK: - BorderWideStyle
extension Style.Button {
    struct BorderWideStyle: ButtonStyle {
        let color: Color
        let textColor: Color

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(textColor)
                .appFontMediumSize16()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 1)
                }
                .opacity(configuration.isPressed ? 0.4 : 1)
        }
    }
}

// MARK: - ButtonStyle+BorderWideStyle
extension ButtonStyle where Self == Style.Button.BorderWideStyle {
    static func borderWide(
        color: Color,
        textColor: Color
    ) -> Style.Button.BorderWideStyle {
        Style.Button.BorderWideStyle(color: color, textColor: textColor)
    }
}

// MARK: - Previews
#if !RELEASE
struct BorderButtonDemo_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button {
                ()
            } label: {
                Text("OK")
            }
            .buttonStyle(.borderWide(
                color: AppColors.Primary.primarySeaBlue.colorSwiftUI,
                textColor: AppColors.Primary.primarySeaBlue.colorSwiftUI
            ))
            .padding([.leading, .trailing], 16)
        }
        .previewDevice(.iPhone15Pro)
    }
}
#endif
