//
//  EmailTextField.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 03.12.2025.
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
import Contacts

private typealias CurrentView = EmailTextField
private typealias Assets = AppAssets.Shared

public struct EmailTextField: View {
    // MARK: - Public Properties
    let description: String?
    let descriptionAccessory: AppTextField.DescriptionAccessory?
    let font: Font
    let backgroundColor: Color
    let placeholder: String
    let leadingAccessory: Image?
    let tapDestination: AppTextField.TapDestination
    var state: AppTextField.TextFieldStates

    @Binding var text: String

    // MARK: - Private Properties
    @StateObject private var viewModel: ContactsTextFieldViewModel
    @State private var enableTextMasking: Bool

    // MARK: - Init
    public init(
        text: Binding<String>,
        description: String? = nil,
        descriptionAccessory: AppTextField.DescriptionAccessory? = nil,
        font: Font = FontBuilder.buildRegular(size: 14),
        backgroundColor: Color = AppColors.Gray.gray5.colorSwiftUI,
        placeholder: String = "",
        leadingAccessory: Image? = nil,
        state: AppTextField.TextFieldStates = .default,
        tapDestination: AppTextField.TapDestination = .`self`(()),
        permissionsProvider: ContactsPermissionsProvider
    ) {
        self._text = .init(projectedValue: text)
        self.description = description
        self.descriptionAccessory = descriptionAccessory
        self.font = font
        self.backgroundColor = backgroundColor
        self.placeholder = placeholder
        self.leadingAccessory = leadingAccessory
        self.tapDestination = tapDestination
        self.state = state
        self.enableTextMasking = true
        self._viewModel = StateObject(wrappedValue: ContactsTextFieldViewModel(permissionsProvider: permissionsProvider))
    }

    // MARK: - Body
    public var body: some View {
        AppTextField(
            text: $text,
            description: description,
            descriptionAccessory: descriptionAccessory,
            font: font,
            backgroundColor: backgroundColor,
            placeholder: placeholder,
            leadingAccessory: leadingAccessory,
            trailingItem: .custom(content: AnyView(trailingItemView())),
            state: state,
            tapDestination: tapDestination
        )
        .installAppAlert(manager: viewModel.alertManager)
        .sheet(isPresented: $viewModel.isShowingContactPicker) {
            ContactPicker(pickerType: .emailAddress) { phone in text = phone }
        }
    }

    @ViewBuilder
    private func trailingItemView() -> some View {
        Button(action: viewModel.checkContactsAccessAndShowPicker) {
            Assets.sharedPhoneBook.imageSwiftUI
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        }
        .padding(16)
        .contentShape(.rect)
    }
}

// MARK: - Previews
#if !RELEASE
struct EmailTextField_Previews: PreviewProvider {
    final class ContactsPermissionsProviderMock: ContactsPermissionsProvider {
        func requestContacts() async -> CNAuthorizationStatus {
            .authorized
        }
    }

    struct Container: View {
        // MARK: - FocusField
        private enum FocusField {
            case textField
        }

        @State private var text: String = ""

        @FocusState private var isFieldFocus: FocusField?

        var body: some View {
            GeometryReader { proxy in
                VStack {
                    CurrentView(
                        text: $text,
                        description: "Username",
                        placeholder: "Enter email",
                        leadingAccessory: AppAssets.Shared.sharedEmailIcon.imageSwiftUI,
                        tapDestination: .`self`(isFieldFocus = .textField),
                        permissionsProvider: ContactsPermissionsProviderMock()
                    )
                    .focused($isFieldFocus, equals: .textField)
                    .padding()
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    static var previews: some View {
        Container()
            .previewDevice(.iPhone15Pro)
    }
}
#endif
