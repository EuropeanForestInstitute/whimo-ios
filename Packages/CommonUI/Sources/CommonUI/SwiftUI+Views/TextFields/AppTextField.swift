//
//  AppTextField.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 30.04.2025.
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
import Utility
import Resources

private typealias CurrentView = AppTextField

public struct AppTextField: View {
    // MARK: - TapDestination
    public enum TapDestination {
        case `self`(@autoclosure () -> Void)
        case textField(@autoclosure () -> Void)
    }

    // MARK: - FocusField
    private enum FocusField {
        case textField
        case secureField
    }

    // MARK: - Text Field States
    public enum TextFieldStates: Equatable {
        case `default`
        case disabled
        case failed(errorText: String)

        var color: Color {
            switch self {
                case .default:
                    AppColors.Gray.gray10.colorSwiftUI
                case .disabled:
                    AppColors.Gray.gray10.colorSwiftUI
                case .failed:
                    .red
            }
        }

        var textColor: Color {
            switch self {
                case .default:
                    AppColors.Gray.gray90.colorSwiftUI
                case .disabled:
                    AppColors.Gray.gray30.colorSwiftUI
                case .failed:
                    AppColors.Gray.gray90.colorSwiftUI
            }
        }

        var descriptionColor: Color {
            switch self {
                case .default:
                    AppColors.Gray.gray90.colorSwiftUI
                case .disabled:
                    AppColors.Gray.gray30.colorSwiftUI
                case .failed:
                    AppColors.Gray.gray90.colorSwiftUI
            }
        }
    }

    // MARK: - DescriptionAccessory
    public struct DescriptionAccessory {
        public let text: String
        public let action: () -> Void

        public init(text: String, action: @escaping () -> Void) {
            self.text = text
            self.action = action
        }

        public var button: some View {
            Button {
                action()
            } label: {
                Text(text)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
        }
    }

    // MARK: - TrailingItem
    public enum TrailingItem {
        case secureText
        case custom(content: AnyView)
        case none
    }

    // MARK: - Public Properties
    let description: String?
    let descriptionAccessory: DescriptionAccessory?
    let font: Font
    let backgroundColor: Color
    let placeholder: String
    let leadingAccessory: Image?
    let trailingItem: TrailingItem
    let tapDestination: TapDestination
    @Binding var text: String
    var state: TextFieldStates

    // MARK: Private Properties
    @State private var enableTextMasking: Bool
    @FocusState private var isFieldFocus: FocusField?

    // MARK: - Init
    public init(
        description: String? = nil,
        descriptionAccessory: DescriptionAccessory? = nil,
        font: Font = FontBuilder.buildRegular(size: 14),
        backgroundColor: Color = AppColors.Gray.gray5.colorSwiftUI,
        placeholder: String = "",
        leadingAccessory: Image? = nil,
        trailingItem: TrailingItem = .none,
        text: Binding<String>,
        state: TextFieldStates = .default,
        tapDestination: TapDestination = .`self`(())
    ) {
        self.description = description
        self.descriptionAccessory = descriptionAccessory
        self.font = font
        self.backgroundColor = backgroundColor
        self.placeholder = placeholder
        self.leadingAccessory = leadingAccessory
        self.trailingItem = trailingItem
        self.tapDestination = tapDestination
        self._text = .init(projectedValue: text)
        self.state = state
        self.enableTextMasking = true
    }

    // MARK: - Body
    public var body: some View {
        content()
            .onChange(of: enableTextMasking) { value in
                isFieldFocus = value ? .secureField : .textField
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        if case .`self`(let closure) = self.tapDestination {
                            closure()
                        }
                    }
            )
    }
}

// MARK: - Private Layout
private extension CurrentView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 4) {
            if let description {
                descriptionView(description: description)
            }
            styledTextFieldView()
            if case .failed(let errorText) = state {
                failedDescriptionView(errorText: errorText)
            }
        }
    }

    @ViewBuilder func descriptionView(description: String) -> some View {
        HStack(spacing: .zero) {
            Text(description)
                .appFontRegularSize16()
                .foregroundStyle(state.descriptionColor)
            Spacer()
            if let descriptionAccessory {
                descriptionAccessory.button
            }
        }
        .frame(height: 22)
    }

    @ViewBuilder func styledTextFieldView() -> some View {
        HStack(spacing: 6) {
            if let leadingAccessory {
                leadingAccessory
                    .frame(width: 20, height: 20)
            }
            textFieldView()
                .font(font)
                .disabled(state == .disabled)
            switch trailingItem {
                case .secureText:
                    showSecureTextButtonView()
                case .custom(let content):
                    content
                case .none:
                    EmptyView()
            }
        }
        .padding([.horizontal], 16)
        .frame(height: 48)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    state.color,
                    lineWidth: 1
                )
        }
        .onTapGesture {
            if case .textField(let closure) = self.tapDestination {
                closure()
            }
        }
    }

    @ViewBuilder func textFieldView() -> some View {
        VStack {
            switch trailingItem {
                case .secureText:
                    secureTextFieldView()
                default:
                    TextField(
                        "Input field",
                        text: self.$text,
                        prompt: placeholderText(self.placeholder)
                    )
            }
        }
        .foregroundStyle(state.textColor)
    }

    @ViewBuilder func secureTextFieldView() -> some View {
        if self.enableTextMasking {
            SecureField(
                "Secure input field",
                text: self.$text,
                prompt: placeholderText(self.placeholder)
            )
            .focused($isFieldFocus, equals: .secureField)
        } else {
            TextField(
                "Secure input field",
                text: self.$text,
                prompt: placeholderText(self.placeholder)
            )
            .focused($isFieldFocus, equals: .textField)
        }
    }

    @ViewBuilder func showSecureTextButtonView() -> some View {
        Button {
            self.enableTextMasking.toggle()
        } label: {
            VStack {
                Image(
                    uiImage: enableTextMasking ? AppAssets.Shared.sharedShowPasswordIcon.image : AppAssets.Shared.sharedHidePasswordIcon.image
                )
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            }
            .frame(width: 36, height: 36)
        }
    }

    @ViewBuilder func failedDescriptionView(errorText: String) -> some View {
        HStack(spacing: .zero) {
            Text(errorText)
                .appFontRegularSize16()
                .foregroundStyle(.red)
                .padding([.leading], 4)
            Spacer()
        }
    }

    @ViewBuilder func placeholderText(_ text: String) -> Text {
        Text(text).foregroundColor(AppColors.Gray.gray40.colorSwiftUI)
    }
}

// MARK: - Previews
#if !RELEASE
struct AppTextField_Previews: PreviewProvider {
    struct Container: View {
        // MARK: - FocusField
        private enum FocusField {
            case textField
//            case secureField
        }

        @State private var text: String = ""
        @State private var password: String = ""

        @FocusState private var isFieldFocus: FocusField?

        var body: some View {
            GeometryReader { proxy in
                VStack {
                    CurrentView(
                        description: "Username",
                        placeholder: "Enter email, phone number or user ID",
                        leadingAccessory: AppAssets.Shared.sharedUserIcon.imageSwiftUI,
                        text: $text,
                        tapDestination: .`self`(isFieldFocus = .textField)
                    )
                    .focused($isFieldFocus, equals: .textField)
                    .padding()

                    CurrentView(
                        description: "Username",
                        placeholder: "Enter email, phone number or user ID",
                        leadingAccessory: AppAssets.Shared.sharedUserIcon.imageSwiftUI,
                        text: $text,
                        state: .disabled,
                        tapDestination: .`self`(isFieldFocus = .textField)
                    )
                    .focused($isFieldFocus, equals: .textField)
                    .padding()

                    CurrentView(
                        description: "Password",
                        descriptionAccessory: .init(text: "Forgot password?", action: { }),
                        placeholder: "Enter password",
                        leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                        trailingItem: .secureText,
                        text: $password,
                        tapDestination: .`self`(debugPrint("tapped"))
                    )
                    .padding()

                    CurrentView(
                        trailingItem: .custom(content: AnyView(VStack {
                            Text("kg")
                                .padding(.horizontal, 8)
                        })),
                        text: $text
                    )
                    .padding()
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    static var previews: some View {
        Container()
//            .accentColor(AppColors.accentColor.colorSwiftUI)
            .previewDevice(.iPhone15Pro)
    }
}
#endif
