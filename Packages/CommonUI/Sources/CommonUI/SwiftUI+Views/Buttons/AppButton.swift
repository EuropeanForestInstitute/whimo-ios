//
//  AppButton.swift
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

// MARK: - AppButton
public struct AppButton: View {
    // MARK: - ButtonStyle
    public enum ButtonStyle {
        case prominent
        case bordered
        case destructive

        var textColor: Color {
            switch self {
                case .prominent:
                    AppColors.Other.white.colorSwiftUI
                case .bordered:
                    AppColors.Gray.gray90.colorSwiftUI
                case .destructive:
                    AppColors.Other.white.colorSwiftUI
            }
        }

        var backgroundColor: Color {
            switch self {
                case .prominent:
                    AppColors.Primary.primarySeaBlue.colorSwiftUI
                case .bordered:
                    AppColors.Gray.gray10.colorSwiftUI
                case .destructive:
                    AppColors.Expanded.expandedError.colorSwiftUI
            }
        }

        var pressedBackgroundColor: Color {
            switch self {
                case .prominent:
                    AppColors.Primary.primaryBerryBlue.colorSwiftUI
                case .bordered:
                    AppColors.Gray.gray10.colorSwiftUI
                case .destructive:
                    AppColors.Expanded.expandedError.colorSwiftUI
            }
        }
    }

    // MARK: - Properties
    let title: String?
    let leadingAccessory: Image?
    let style: ButtonStyle
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - Init
    public init(
        title: String? = nil,
        leadingAccessory: Image? = nil,
        style: ButtonStyle = .prominent,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.leadingAccessory = leadingAccessory
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: - Body
    public var body: some View {
        Group {
            switch style {
                case .prominent:
                    content()
                        .foregroundStyle(style.textColor)
                        .buttonStyle(.prominent(
                            color: style.backgroundColor,
                            pressedColor: style.pressedBackgroundColor,
                            isEnabled: isEnabled
                        ))
                case .bordered:
                    content()
                        .buttonStyle(.borderWide(
                            color: style.backgroundColor,
                            textColor: style.textColor
                        ))
                        .background {
                            BackgroundShadowView(style: .card)
                        }
                case .destructive:
                    content()
                        .foregroundStyle(style.textColor)
                        .buttonStyle(.prominent(color: style.backgroundColor))
            }
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Private Layout
private extension AppButton {
    @ViewBuilder func content() -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if let leadingAccessory {
                    leadingAccessory
                        .renderingMode(.template)
                        .overlay {
                            leadingAccessory
                        }
                }
                if let title {
                    label(title: title)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder func label(title: String) -> some View {
        Text(title)
            .padding(.horizontal, 6)
            .frame(height: 22)
    }
}

// MARK: - Preview
struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppButton(title: "Register") { }

            AppButton(title: "Log in", style: .bordered) { }

            AppButton(
                title: "Continue with Apple",
                leadingAccessory: AppAssets.Auth.authAppleIcon.imageSwiftUI,
                style: .bordered
            ) { }

            AppButton(
                title: "Continue with Google",
                leadingAccessory: AppAssets.Auth.authGoogleIcon.imageSwiftUI,
                style: .bordered
            ) { }

            AppButton(
                leadingAccessory: AppAssets.Home.homeCalendarIcon.imageSwiftUI,
                style: .bordered
            ) {
                ()
            }
            .frame(width: 48)

            AppButton(
                title: "Delete",
                style: .destructive
            ) { }
        }
        .padding()
        .previewDisplayName("enabled states")

        VStack {
            AppButton(title: "Register", isEnabled: false) { }

            AppButton(title: "Log in", style: .bordered, isEnabled: false) { }

            AppButton(
                title: "Continue with Apple",
                leadingAccessory: AppAssets.Auth.authAppleIcon.imageSwiftUI,
                style: .bordered,
                isEnabled: false
            ) { }

            AppButton(
                title: "Continue with Google",
                leadingAccessory: AppAssets.Auth.authGoogleIcon.imageSwiftUI,
                style: .bordered,
                isEnabled: false
            ) { }

            AppButton(
                leadingAccessory: AppAssets.Home.homeCalendarIcon.imageSwiftUI,
                style: .bordered,
                isEnabled: false
            ) {
                ()
            }
            .frame(width: 48)

            AppButton(
                title: "Delete",
                style: .destructive,
                isEnabled: false
            ) { }
        }
        .padding()
        .previewDisplayName("disabled states")
    }
}
