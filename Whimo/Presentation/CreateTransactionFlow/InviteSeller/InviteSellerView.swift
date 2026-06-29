//
//  InviteSellerView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.08.2025.
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
import Contacts

private typealias Module = InviteSellerModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.InviteSeller

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

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

        private var emailTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.email] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        private var phoneTextFieldState: AppPhoneNumberTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.phone] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
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
            formView()
                .padding(.bottom, 72)
            footerView()
        }
    }

    @ViewBuilder func formView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                subtitle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                textFields()
            }
            .padding(16)
        }
    }

    @ViewBuilder func subtitle() -> some View {
        Text(Localization.subtitle)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }

    @ViewBuilder func textFields() -> some View {
        VStack(spacing: 16) {
            // email
            EmailTextField(
                text: email,
                description: Localization.TextFields.Email.description,
                placeholder: Localization.TextFields.Email.placeholder,
                leadingAccessory: AppAssets.Shared.sharedEmailIcon.imageSwiftUI,
                state: emailTextFieldState,
                tapDestination: .textField(keyboardActiveField = .email),
                permissionsProvider: viewModel.permissionsProvider
            )
            .focused($keyboardActiveField, equals: .email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .submitLabel(.next)

            textFieldsDivider()

            // phone
            AppPhoneNumberTextField(
                text: phone,
                description: Localization.TextFields.PhoneNumber.description,
                state: phoneTextFieldState,
                trailingItem: .phonebook(permissionsProvider: viewModel.permissionsProvider)
            )
            .focused($keyboardActiveField, equals: .phone)
            .textContentType(.telephoneNumber)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func footerView() -> some View {
        VStack {
            Spacer()
            confirmButtton()
                .padding(.top, 12)
                .padding(.bottom, 16)
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

    @ViewBuilder func confirmButtton() -> some View {
        AppButton(
            title: Localization.Buttons.confirm,
            isEnabled: viewModel.isSaveButtonEnabled,
            action: didTapConfirm
        )
        .animation(.snappy, value: viewModel.isSaveButtonEnabled)
    }

    @ViewBuilder func textFieldsDivider() -> some View {
        HStack(spacing: 16) {
            DashDivider()
                .clipped()
            Text(Localization.or)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            DashDivider()
                .clipped()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func focusNextField() {
        switch keyboardActiveField {
            case .email:
                keyboardActiveField = .phone
            case .phone:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func didTapConfirm() {
        keyboardActiveField = nil
        Task { await viewModel.didTapConfirm() }
    }
}

// MARK: - Previews
#if !RELEASE
struct InviteSellerView_Previews: PreviewProvider {
    static var previews: some View {
        InviteSellerModule.assemble()
    }
}
#endif
