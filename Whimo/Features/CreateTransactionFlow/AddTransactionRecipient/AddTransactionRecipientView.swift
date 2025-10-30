//
//  AddTransactionRecipientView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 11.06.2025.
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

private typealias Module = AddTransactionRecipientModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.AddTransactionRecipient

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

        private var titleText: String {
            switch viewModel.action {
                case .buy:
                    Localization.Supplier.title
                case .sell:
                    Localization.Buyer.title
            }
        }

        private var subtitleText: String {
            switch viewModel.action {
                case .buy:
                    Localization.Supplier.subtitle
                case .sell:
                    Localization.Buyer.subtitle
            }
        }

        private var recipientDescriptionText: String {
            switch viewModel.action {
                case .buy:
                    Localization.Supplier.TextFields.UserID.description
                case .sell:
                    Localization.Buyer.TextFields.UserID.description
            }
        }

        private var recipientPlaceholderText: String {
            switch viewModel.action {
                case .buy:
                    Localization.Supplier.TextFields.UserID.placeholder
                case .sell:
                    Localization.Buyer.TextFields.UserID.placeholder
            }
        }

        private var recipientID: Binding<String> {
            .init {
                viewModel.recipient.recipientID
            } set: { newValue in
                viewModel.recipient.recipientID = newValue
            }
        }

        private var email: Binding<String> {
            .init {
                viewModel.recipient.email
            } set: { newValue in
                viewModel.recipient.email = newValue
            }
        }

        private var phone: Binding<String> {
            .init {
                viewModel.recipient.phone
            } set: { newValue in
                viewModel.recipient.phone = newValue
            }
        }

        private var isConfirmButtonEnabled: Bool {
            !(viewModel.recipient.recipientContact ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }

        private var emailTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.email] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        // MARK: - Init
        init(action: TransactionModel.Action) {
            _viewModel = .init(wrappedValue: .init(action: action))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: titleText)
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
                .keyboardDefaultToolbar(action: self.keyboardActiveField = .none)
                .onChange(of: keyboardActiveField) { newValue in
                    viewModel.setKeyboardActiveField(newValue)
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    subtitle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    textFields()
                }
                .padding(16)
            }
            .padding(.bottom, 72)
            VStack {
                Spacer()
                confirmButtton()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background {
                        if keyboardActiveField == nil {
                            AppColors.Other.white.colorSwiftUI
                                .ignoresSafeArea()
                        } else {
                            AppColors.Other.white.colorSwiftUI
                                .ignoresSafeArea()
                                .shadow(radius: 7, x: 0, y: 7)
                        }
                    }
            }
        }
    }

    @ViewBuilder func subtitle() -> some View {
        Text(subtitleText)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }

    @ViewBuilder func textFields() -> some View {
        VStack(spacing: 16) {
            // recipient
            AppTextField(
                description: recipientDescriptionText,
                placeholder: recipientPlaceholderText,
                leadingAccessory: AppAssets.Shared.sharedUserIcon.imageSwiftUI,
                text: recipientID,
                tapDestination: .textField(keyboardActiveField = .recipientID)
            )
            .focused($keyboardActiveField, equals: .recipientID)
            .submitLabel(.next)

            // email
            AppTextField(
                description: Localization.TextFields.Email.description,
                placeholder: Localization.TextFields.Email.placeholder,
                leadingAccessory: AppAssets.Shared.sharedEmailIcon.imageSwiftUI,
                text: email,
                state: emailTextFieldState,
                tapDestination: .textField(keyboardActiveField = .email)
            )
            .focused($keyboardActiveField, equals: .email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .submitLabel(.next)

            // phone
            AppPhoneNumberTextField(
                description: Localization.TextFields.PhoneNumber.description,
                text: phone,
                trailingItem: .phonebook(permissionsProvider: viewModel.permissionsProvider)
            )
            .focused($keyboardActiveField, equals: .phone)
            .textContentType(.telephoneNumber)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func confirmButtton() -> some View {
        AppButton(
            title: Localization.Buttons.confirm,
            isEnabled: isConfirmButtonEnabled,
            action: didTapConfirm
        )
        .animation(.snappy, value: isConfirmButtonEnabled)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func focusNextField() {
        switch keyboardActiveField {
            case .recipientID:
                keyboardActiveField = .email
            case .email:
                keyboardActiveField = .phone
            case .phone:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func didTapConfirm() {
        viewModel.didTapConfirm()
    }
}

// MARK: - Previews
#if !RELEASE
struct AddTransactionRecipientView_Previews: PreviewProvider {
    struct Container: View {
        private let action: TransactionModel.Action

        init(action: TransactionModel.Action, recipient: TransactionType.Recipient) {
            self.action = action

            @Inject(\.appState) var appState
            appState.createTransaction.dispatch { state in
                state.transactionType = .downstream(action: action, recipient: recipient)
            }
        }

        var body: some View {
            AddTransactionRecipientModule.assemble(action: action)
        }
    }

    static var previews: some View {
        Container(
            action: .buy,
            recipient: .init(
                recipientID: "123-456-789",
                email: "qwe@gmail.com",
                phone: "+380 98 11 11 111"
            )
        )
    }
}
#endif
