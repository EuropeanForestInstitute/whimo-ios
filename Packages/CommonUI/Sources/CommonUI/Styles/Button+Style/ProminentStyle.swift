//
//  ProminentStyle.swift
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

// MARK: - ProminentStyle
extension Style.Button {
    struct ProminentStyle: ButtonStyle {
        let color: Color
        let textColor: Color
        let pressedColor: Color?
        let isEnabled: Bool

        func makeBody(configuration: Configuration) -> some View {
            let backgroundColor = isEnabled ? color : color.opacity(0.5)
            let background = configuration.isPressed
            ? (pressedColor ?? backgroundColor.opacity(0.4))
            : backgroundColor

            configuration.label
                .foregroundStyle(textColor)
                .appFontMediumSize16()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(background)
                    }
                }
        }
    }
}

// MARK: - ButtonStyle+ProminentStyle
extension ButtonStyle where Self == Style.Button.ProminentStyle {
    static func prominent(
        color: Color = AppColors.Primary.primarySeaBlue.colorSwiftUI,
        textColor: Color = AppColors.Other.white.colorSwiftUI,
        pressedColor: Color? = AppColors.Primary.primaryBerryBlue.colorSwiftUI,
        isEnabled: Bool = true
    ) -> Style.Button.ProminentStyle {
        Style.Button.ProminentStyle(
            color: color,
            textColor: textColor,
            pressedColor: pressedColor,
            isEnabled: isEnabled
        )
    }
}

extension Button {
    public func applyProminentStyle(
        color: Color = AppColors.Primary.primarySeaBlue.colorSwiftUI,
        textColor: Color = AppColors.Other.white.colorSwiftUI,
        pressedColor: Color? = AppColors.Primary.primaryBerryBlue.colorSwiftUI,
        isEnabled: Bool = true
    ) -> some View {
        buttonStyle(.prominent(
            color: color,
            textColor: textColor,
            pressedColor: pressedColor,
            isEnabled: isEnabled
        ))
    }
}

// MARK: - Previews
#if !RELEASE
struct WideButtonDemo_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button {
                ()
            } label: {
                Text("OK")
            }
            .buttonStyle(.prominent(
                color: AppColors.Primary.primarySeaBlue.colorSwiftUI,
                pressedColor: AppColors.Primary.primaryBerryBlue.colorSwiftUI
            ))

            Button {
                ()
            } label: {
                Text("OK")
            }
            .applyProminentStyle()
            .frame(width: 200)

            Button {
                ()
            } label: {
                Text("OK")
            }
            .buttonStyle(.prominent(
                color: AppColors.Primary.primarySeaBlue.colorSwiftUI,
                pressedColor: AppColors.Primary.primaryBerryBlue.colorSwiftUI,
                isEnabled: false
            ))
        }
        .padding([.leading, .trailing], 16)
        .previewDevice(.iPhone15Pro)
    }
}
#endif
