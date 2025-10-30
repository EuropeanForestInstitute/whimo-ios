//
//  RegisterView.swift
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
import struct Utility.AttributedStringBuilder

private typealias Module = RegisterModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Register

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english
        @FocusState private var keyboardActiveField: KeyboardField?

        private var termsAttributedText: AttributedString {
            AttributedStringBuilder.build(from: [
                (
                    Localization.AcceptTerms.title1,
                    .init([.font: AppFonts.FiraSans.regular.font(size: 16)])
                ),
                (
                    Localization.AcceptTerms.title2,
                    .init([.font: AppFonts.FiraSans.medium.font(size: 16)])
                ),
            ])
        }

        private var email: Binding<String> {
            .init {
                viewModel.credentials.email
            } set: { newValue in
                viewModel.credentials.email = newValue
            }
        }

        private var phone: Binding<String> {
            .init {
                viewModel.credentials.phone
            } set: { newValue in
                viewModel.credentials.phone = newValue
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

        private var isTermsAccepted: Binding<Bool> {
            .init {
                viewModel.credentials.isTermsAccepted
            } set: { newValue in
                viewModel.credentials.isTermsAccepted = newValue
            }
        }

        private var emailTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.email] {
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

        private var confirmPasswordTextFieldState: AppTextField.TextFieldStates {
            if let error = viewModel.validationErrors[.confirmPassword] {
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
                .sheet(isPresented: $viewModel.enableSelectGadgetAlert) {
                    ChooseVerifyMethodView(didTapEmail: didTapVerifyEmail, didTapPhone: didTapVerifyPhone)
                        .selfSizedSheet()
                        .background { OverridingBackgroundView() }
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
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    subtitle()
                        .padding(.horizontal, 16)
                    registerForm()
                        .padding(.horizontal, 16)
                }
                HStack(spacing: 12) {
                    AppCheckBox(isSelected: isTermsAccepted)
                    Text(termsAttributedText)
                        .appFontRegularSize16()
                        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                    Spacer()
                }
                .padding(.horizontal, 16)
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
    }

    @ViewBuilder func registerForm() -> some View {
        VStack(spacing: 16) {
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
                text: phone
            )
            .focused($keyboardActiveField, equals: .phone)
            .textContentType(.telephoneNumber)
            .submitLabel(.next)

            // pass
            AppTextField(
                description: Localization.TextFields.Password.description,
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                isSecure: true,
                text: password,
                state: passwordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .password)
            )
            .focused($keyboardActiveField, equals: .password)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .submitLabel(.next)

            // repeat pass
            AppTextField(
                description: Localization.TextFields.ConfirmPassword.description,
                placeholder: Localization.TextFields.ConfirmPassword.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                isSecure: true,
                text: repeatPassword,
                state: confirmPasswordTextFieldState,
                tapDestination: .textField(keyboardActiveField = .confirmPassword)
            )
            .focused($keyboardActiveField, equals: .confirmPassword)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    @ViewBuilder func socialLoginButtons() -> some View {
        VStack(spacing: 16) {
            AppButton(
                title: Localization.RegisterButtons.register,
                isEnabled: viewModel.enableRegisterButton,
                action: didTapRegister
            )
            .animation(.snappy(duration: 0.23), value: viewModel.enableRegisterButton)
            buttonsDivider()
            AppButton(
                title: Localization.RegisterButtons.googleRegister,
                leadingAccessory: AppAssets.Auth.authGoogleIcon.imageSwiftUI,
                style: .bordered,
                action: didTapGoogleAuth
            )
            AppButton(
                title: Localization.RegisterButtons.appleRegister,
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
            Text(Localization.LoginField.title)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Button {
                didTapLogin()
            } label: {
                Text(Localization.LoginField.button)
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
            case .email:
                keyboardActiveField = .phone
            case .phone:
                keyboardActiveField = .password
            case .password:
                keyboardActiveField = .confirmPassword
            case .confirmPassword:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func didTapRegister() {
        Task { await viewModel.didTapSignUp() }
    }

    func didTapLogin() {
        var routes = navigator.routes
        routes.removeLast()

        switch routes.last?.screen {
            case .login:
                navigator.dismiss()
            default:
                navigator.presentCover(.login, embedInNavigationView: true)
        }
    }

    func didTapGoogleAuth() {
        Task { await viewModel.didTapGoogleAuth() }
    }

    func didTapAppleAuth() {
        Task { await viewModel.didTapAppleAuth() }
    }

    func didTapChangeLanguage() {
        navigator.presentSheet(.changeLanguage)
    }

    func didTapVerifyEmail() {
        viewModel.didTapVerifyEmail()
    }
    func didTapVerifyPhone() {
        viewModel.didTapVerifyPhone()
    }
}

// MARK: - Previews
#if !RELEASE
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterModule.assemble()
    }
}
#endif
