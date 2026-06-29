//
//  AppPhoneNumberTextField.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 02.05.2025.
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
import PhoneNumberKit

private typealias CurrentView = AppPhoneNumberTextField
private typealias Assets = AppAssets.Shared

public struct AppPhoneNumberTextField: View {
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

    // MARK: - TrailingItem
    public enum TrailingItem {
        case phonebook(permissionsProvider: ContactsPermissionsProvider)
        case none
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

    // MARK: - Public Properties
    let description: String
    let placeholder: String
    let tapDestination: TapDestination
    let trailingItem: TrailingItem
    var state: TextFieldStates

    @Binding var text: String

    // MARK: - Private Properties
    @StateObject private var viewModel: ContactsTextFieldViewModel
    private let phoneNumberUtility: PhoneNumberUtility = .init()

    // MARK: - Init

    /// Initializes the phone number text field with optional contacts integration
    /// - Parameters:
    ///   - text: Binding to the phone number string value
    ///   - description: Field description text displayed above the text field
    ///   - placeholder: Placeholder text shown when field is empty (default: "")
    ///   - state: Current state of the text field (default: .default)
    ///   - trailingItem: Trailing item configuration
    ///   - tapDestination: Defines where tap gestures are handled (default: .self)
    public init(
        text: Binding<String>,
        description: String,
        placeholder: String = "",
        state: TextFieldStates = .default,
        trailingItem: TrailingItem = .none,
        tapDestination: TapDestination = .`self`(()),
    ) {
        self._text = .init(projectedValue: text)
        self.description = description
        self.placeholder = placeholder
        self.tapDestination = tapDestination
        self.state = state
        self.trailingItem = trailingItem

        switch trailingItem {
            case .phonebook(let permissionsProvider):
                self._viewModel = StateObject(wrappedValue: ContactsTextFieldViewModel(permissionsProvider: permissionsProvider))
            case .none:
                self._viewModel = StateObject(wrappedValue: ContactsTextFieldViewModel(permissionsProvider: nil))
        }
    }

    // MARK: - Body
    public var body: some View {
        content()
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        if case .`self`(let closure) = self.tapDestination {
                            closure()
                        }
                    }
            )
            .installAppAlert(manager: viewModel.alertManager)
            .sheet(isPresented: $viewModel.isShowingContactPicker) {
                ContactPicker { phone in
                    let formatted = formatPickerProperty(phone)
                    text = formatted
                }
            }
    }
}

// MARK: - Private Layout
private extension CurrentView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 4) {
            descriptionView()
            styledTextFieldView()
            if case .failed(let errorText) = state {
                failedDescriptionView(errorText: errorText)
            }
        }
    }

    @ViewBuilder func descriptionView() -> some View {
        HStack(spacing: .zero) {
            Text(self.description)
                .appFontRegularSize16()
                .foregroundStyle(state.descriptionColor)
            Spacer()
        }
        .frame(height: 22)
    }

    @ViewBuilder func styledTextFieldView() -> some View {
        HStack(spacing: 6) {
            textFieldView()
                .padding(.leading, 16)
            trailingItemView()
        }
        .frame(height: 48)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.Gray.gray5.colorSwiftUI)
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
        PhoneTextField(
            textColor: state.textColor,
            withDefaultPickerUI: true,
            withFlag: true,
            withPrefix: true,
            withExamplePlaceholder: true,
            text: self.$text
        )
        .disabled(state == .disabled)
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

    @ViewBuilder func trailingItemView() -> some View {
        switch trailingItem {
            case .phonebook:
                HStack {
                    Spacer()
                    Button(action: viewModel.checkContactsAccessAndShowPicker) {
                        Assets.sharedPhoneBook.imageSwiftUI
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    .padding(16)
                    .contentShape(.rect)
                }
            case .none:
                EmptyView()
        }
    }
}

// MARK: - Private Methods
private extension CurrentView {
    func formatPickerProperty(_ phone: String) -> String {
        do {
            let phoneNumber = try phoneNumberUtility.parse(phone)
            let formatted = phoneNumberUtility.format(phoneNumber, toType: .international)
            return formatted
        } catch {
            log.error("An error occured: \(error)")
            return phone
        }
    }
}

// MARK: - Previews
#if !RELEASE
import Contacts
struct AppPhoneNumberTextField_Previews: PreviewProvider {
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

        @State private var phone: String = ""
        @State private var password: String = ""

        @FocusState private var isFieldFocus: FocusField?

        var body: some View {
            GeometryReader { proxy in
                VStack {
                    CurrentView(
                        text: $phone,
                        description: "Username",
                        placeholder: "Enter email, phone number or user ID",
                        tapDestination: .`self`({ isFieldFocus = .textField }())
                    )
                    .padding()
                    CurrentView(
                        text: $phone,
                        description: "Phone*",
                        placeholder: "",
                        state: .failed(errorText: "Not phone number")
                    )
                    .padding()
                    CurrentView(
                        text: $phone,
                        description: "Phone*",
                        placeholder: "",
                        trailingItem: .phonebook(permissionsProvider: ContactsPermissionsProviderMock())
                    )
                    .padding()
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    static var previews: some View {
        Container()
            .previewDevice(.iPhone15Pro)
            .preferredColorScheme(.light)
            .previewDisplayName("Light")

        Container()
            .previewDevice(.iPhone15Pro)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
    }
}
#endif
