//
//  PhoneTextField.swift
//  Tollroad
//
//  Created by developer on 20.02.2024.
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
import PhoneNumberKit
import Resources

private typealias CurrentView = PhoneTextField

// MARK: - PhoneTextField
public struct PhoneTextField: UIViewRepresentable {
    public typealias UIViewType = PhoneNumberTextFieldOverriding

    // MARK: - Constants
    public static let defaultRegion: String = PhoneNumberUtility.defaultRegionCode()
    public static let defaultMaxDigits: Int = 10

    // MARK: - Public Properties
    let defaultRegion: String
    let maxDigits: Int?
    let textColor: Color
    let placeholderColor: Color
    let font: UIFont
    let enableToolbar: Bool
    let withDefaultPickerUI: Bool
    let withFlag: Bool
    let withPrefix: Bool
    let withExamplePlaceholder: Bool
    @Binding var text: String

    // MARK: - Private Properties
    @AppStorage(.currentLocalize)
    private var currentLocalize: LocalizeKeys = .english

    // MARK: - Public Init
    public init(
        defaultRegion: String = defaultRegion,
        maxDigits: Int? = defaultMaxDigits,
        textColor: Color = AppColors.Gray.gray90.colorSwiftUI,
        placeholderColor: Color = AppColors.Gray.gray40.colorSwiftUI,
        font: UIFont = AppFonts.FiraSans.regular.font(size: 14),
        enableToolbar: Bool = true,
        withDefaultPickerUI: Bool = false,
        withFlag: Bool = false,
        withPrefix: Bool = false,
        withExamplePlaceholder: Bool = false,
        text: Binding<String>
    ) {
        self.defaultRegion = defaultRegion
        self.maxDigits = maxDigits
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.font = font
        self.enableToolbar = enableToolbar
        self.withDefaultPickerUI = withDefaultPickerUI
        self.withFlag = withFlag
        self.withPrefix = withPrefix
        self.withExamplePlaceholder = withExamplePlaceholder
        self._text = .init(projectedValue: text)
    }

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UIViewType {
        let textField: UIViewType = .init(defaultRegion: defaultRegion)

        textField.addTarget(context.coordinator, action: #selector(context.coordinator.textChanged), for: .editingChanged)
        context.coordinator.observe(textField)

        return textField
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) { update(uiView, context: context) }

    public func makeCoordinator() -> Coordinator { .init(text: $text) }
}

// MARK: - Private Methods
private extension CurrentView {
    func update(_ uiView: UIViewType, context: Context) {
        uiView.textFieldOverridingDelegate = context.coordinator
        uiView.maxDigits = maxDigits
        uiView.textColor = .init(textColor)
        uiView.placeholderColor = .init(placeholderColor)
        uiView.font = font
        uiView.enableToolbar = enableToolbar
        uiView.withDefaultPickerUI = withDefaultPickerUI
        uiView.withFlag = withFlag
        uiView.withPrefix = withPrefix
        uiView.withExamplePlaceholder = withExamplePlaceholder
        context.coordinator.applyBindingText(text, to: uiView)
    }
}
