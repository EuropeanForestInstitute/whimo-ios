//
//  LoginView.swift
//  Whimo
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
import CommonUI

private typealias Module = LoginModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Login

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english
        @FocusState private var keyboardActiveField: KeyboardField?

        private var emailName: Binding<String> {
            .init {
                viewModel.credentials.username
            } set: { newValue in
                let password = viewModel.credentials.password
                viewModel.credentials = .email(username: newValue, password: password)
            }
        }

        private var phoneName: Binding<String> {
            .init {
                viewModel.credentials.username
            } set: { newValue in
                let password = viewModel.credentials.password
                viewModel.credentials = .phone(username: newValue, password: password)
            }
        }

        private var password: Binding<String> {
            .init {
                viewModel.credentials.password
            } set: { newValue in
                switch viewModel.credentials {
                    case .email(let username, _):
                        viewModel.credentials = .email(username: username, password: newValue)
                    case .phone(let username, _):
                        viewModel.credentials = .phone(username: username, password: newValue)
                }
            }
        }

        private var selectedCredentialsType: Binding<CredentialsType> {
            .init {
                let credentials = viewModel.credentials
                switch credentials {
                    case .email:
                        return .email
                    case .phone:
                        return .phone
                }
            } set: { newValue in
                toggleSection(newValue: newValue)
            }
        }

        private var usernameTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.username] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        private var usernamePhoneTextFieldState: AppPhoneNumberTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.username] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        private var passwordTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.password] {
                return .failed(errorText: error.localizedDescription)
            }

            return .default
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: Localization.title,
                    showBackButton: false,
                    enableDivider: false
                )
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
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    subtitle()
                    SegmentedPicker(
                        items: viewModel.credentialTypes,
                        selection: selectedCredentialsType,
                        title: { $0.titleText }
                    )
                    loginForm()
                        .padding(.horizontal, 16)
                }
                socialLoginButtons()
                    .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder func subtitle() -> some View {
        Text(Localization.subtitle)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    @ViewBuilder func loginForm() -> some View {
        switch viewModel.credentials {
            case .email:
                emailLoginForm()
            case .phone:
                phoneLoginForm()
        }
    }

    @ViewBuilder func emailLoginForm() -> some View {
        VStack(spacing: 16) {
            AppTextField(
                text: emailName,
                description: Localization.TextFields.Email.description,
                placeholder: Localization.TextFields.Email.placeholder,
                leadingAccessory: AppAssets.Shared.sharedEmailIcon.imageSwiftUI,
                state: usernameTextFieldState,
                tapDestination: .textField(keyboardActiveField = .username)
            )
            .focused($keyboardActiveField, equals: .username)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .submitLabel(.next)
            AppTextField(
                text: password,
                description: Localization.TextFields.Password.description,
                descriptionAccessory: .init(
                    text: Localization.TextFields.Password.descriptionAccessory,
                    action: didTapForgotPassword
                ),
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                state: passwordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .password)
            )
            .focused($keyboardActiveField, equals: .password)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func phoneLoginForm() -> some View {
        VStack(spacing: 16) {
            AppPhoneNumberTextField(
                text: phoneName,
                description: Localization.TextFields.PhoneNumber.description,
                state: usernamePhoneTextFieldState
            )
            .focused($keyboardActiveField, equals: .username)
            .textContentType(.telephoneNumber)
            .submitLabel(.next)
            AppTextField(
                text: password,
                description: Localization.TextFields.Password.description,
                descriptionAccessory: .init(
                    text: Localization.TextFields.Password.descriptionAccessory,
                    action: didTapForgotPassword
                ),
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                state: passwordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .password)
            )
            .focused($keyboardActiveField, equals: .password)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func socialLoginButtons() -> some View {
        VStack(spacing: 16) {
            AppButton(
                title: Localization.LoginButtons.login,
                isEnabled: viewModel.isLoginButtonEnabled,
                action: didTapLogin
            )
            buttonsDivider()
            AppButton(
                title: Localization.LoginButtons.googleLogin,
                leadingAccessory: AppAssets.Auth.authGoogleIcon.imageSwiftUI,
                style: .bordered,
                action: didTapGoogleAuth
            )
            AppButton(
                title: Localization.LoginButtons.appleLogin,
                leadingAccessory: AppAssets.Auth.authAppleIcon.imageSwiftUI,
                style: .bordered,
                action: didTapAppleAuth
            )
            VStack(spacing: 34) {
                registerButton()
                changeLangButton()
                    .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder func buttonsDivider() -> some View {
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

    @ViewBuilder func registerButton() -> some View {
        HStack(spacing: 4) {
            Text(Localization.RegisterField.title)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Button {
                didTapRegister()
            } label: {
                Text(Localization.RegisterField.button)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
        }
    }

    @ViewBuilder func changeLangButton() -> some View {
        Button {
            didTapChangeLanguage()
        } label: {
            HStack(spacing: 6) {
                AppAssets.Auth.authLanguageIcon.imageSwiftUI
                    .renderingMode(.template)
                Text(currentLocalize.title)
                    .appFontMediumSize16()
            }
            .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func focusNextField() {
        switch keyboardActiveField {
            case .username:
                keyboardActiveField = .password
            case .password:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func toggleSection(newValue: LoginModule.CredentialsType) {
        viewModel.setKeyboardActiveField(nil)
        viewModel.flushValidations()
        viewModel.credentials = newValue.credentails()
    }

    func didTapForgotPassword() {
        navigator.push(.forgotPassword)
    }

    func didTapLogin() {
        Task { await viewModel.didTapLogin() }
    }

    func didTapGoogleAuth() {
        Task { await viewModel.didTapGoogleAuth() }
    }

    func didTapAppleAuth() {
        Task { await viewModel.didTapAppleAuth() }
    }

    func didTapRegister() {
        var routes = navigator.routes
        routes.removeLast()

        switch routes.last?.screen {
            case .register:
                navigator.dismiss()
            default:
                navigator.presentCover(.register, embedInNavigationView: true)
        }
    }

    func didTapChangeLanguage() {
        navigator.presentSheet(.changeLanguage)
    }
}

// MARK: - Previews
#if !RELEASE
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginModule.assemble()
    }
}
#endif
