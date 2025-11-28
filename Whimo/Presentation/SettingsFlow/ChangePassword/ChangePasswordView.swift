//
//  ChangePasswordView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

private typealias Module = ChangePasswordModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.ChangePassword

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

        private var currentPassword: Binding<String> {
            .init {
                viewModel.credentials.currentPassword
            } set: { newValue in
                viewModel.credentials.currentPassword = newValue
            }
        }

        private var password: Binding<String> {
            .init {
                viewModel.credentials.password
            } set: { newValue in
                viewModel.credentials.password = newValue
            }
        }

        private var repeatPassword: Binding<String> {
            .init {
                viewModel.credentials.repeatPassword
            } set: { newValue in
                viewModel.credentials.repeatPassword = newValue
            }
        }

        private var passwordTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.password] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        private var confirmPasswordTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.confirmPassword] {
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
                .onChange(of: keyboardActiveField) { newValue in
                    viewModel.setKeyboardActiveField(newValue)
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 32) {
            passwordForm()
            Spacer()
            buttons()
                .padding(.bottom, 12)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    // MARK: - Text Fields
    @ViewBuilder func passwordForm() -> some View {
        VStack(spacing: 16) {
            AppTextField(
                description: Localization.TextFields.CurrentPassword.description,
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                text: currentPassword,
                tapDestination: .textField(keyboardActiveField = .currentPassword)
            )
            .focused($keyboardActiveField, equals: .currentPassword)
            .textContentType(.password)
            .submitLabel(.next)
            AppTextField(
                description: Localization.TextFields.Password.description,
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                text: password,
                state: passwordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .password)
            )
            .focused($keyboardActiveField, equals: .password)
            .textContentType(.newPassword)
            .submitLabel(.next)
            AppTextField(
                description: Localization.TextFields.ConfirmPassword.description,
                placeholder: Localization.TextFields.ConfirmPassword.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                text: repeatPassword,
                state: confirmPasswordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .confirmPassword)
            )
            .focused($keyboardActiveField, equals: .confirmPassword)
            .textContentType(.password)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func buttons() -> some View {
        AppButton(
            title: Localization.Buttons.save,
            isEnabled: viewModel.enableSaveButton,
            action: didTapSave
        )
        .animation(.snappy(duration: 0.23), value: viewModel.enableSaveButton)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func focusNextField() {
        switch keyboardActiveField {
            case .currentPassword:
                keyboardActiveField = .password
            case .password:
                keyboardActiveField = .confirmPassword
            case .confirmPassword:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func didTapSave() {
        Task { await viewModel.didTapSave() }
    }
}

// MARK: - Previews
#if !RELEASE
struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordModule.assemble()
    }
}
#endif
