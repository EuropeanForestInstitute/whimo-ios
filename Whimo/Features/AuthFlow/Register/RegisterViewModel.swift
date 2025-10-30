//
//  RegisterViewModel.swift
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

import Foundation
import Utility
import Resources

private typealias Module = RegisterModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var credentials: Credentials = .empty
        @Published var enableSelectGadgetAlert: Bool = false
        @Published var enableRegisterButton: Bool = false

        private var keyboardActiveField: KeyboardField?
        private(set) var validationErrors: [KeyboardField: Error] = [:]

        // MARK: - Private Properties
        private let phoneNumberFormatter: PhoneNumberFormatter = .flat
        private let passwordValidator: PasswordValidator = .shared
        private let phoneNumberValidator: PhoneNumberValidator = .shared
        private let emailValidator: EmailValidator = .shared
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.authService) private var authService
        @Inject(\.tokenRegistryService) private var tokenRegistryService

        // MARK: - Init
        init() {
            setupBindings()
        }

        // MARK: - ViewModelProtocol
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        func didTapSignUp() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            let success = await signUpRequest(credentials: credentials)
            guard success else { return }

            let enableSelectGadgetAlert = showOTPAlert(credentials: credentials)
            await MainActor.run {
                self.enableSelectGadgetAlert = enableSelectGadgetAlert
            }

            guard !enableSelectGadgetAlert else { return }

            openOTPScreen(credentials: credentials)
        }

        func didTapGoogleAuth() async {
            let success = await signInWithGoogleRequest()
            guard success else { return }

            openAuthorizedZone()
        }

        func didTapAppleAuth() async {
            let success = await signInWithAppleRequest()
            guard success else { return }

            openAuthorizedZone()
        }

        @MainActor
        func didTapVerifyEmail() {
            enableSelectGadgetAlert = false
            openOTPScreen(credentials: credentials)
        }

        @MainActor
        func didTapVerifyPhone() {
            enableSelectGadgetAlert = false
            openOTPScreen(credentials: credentials, reversed: true)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBindings() {
        $credentials
            .sink { [weak self] credentials in
                guard let self else { return }

                let fieldsSuccess = self.validate(
                    email: credentials.email,
                    phone: credentials.phone,
                    password: credentials.password,
                    repeatPassword: credentials.repeatPassword
                )
                let success = fieldsSuccess && credentials.isTermsAccepted
                Task { @MainActor in
                    self.enableRegisterButton = success
                }
            }
            .store(in: cancellable)
        $credentials
            .dropFirst()
            .sink { [weak self] credentials in
                guard let self else { return }

                switch self.keyboardActiveField {
                    case .email:
                        self.validationErrors[.email] = self.emailValidator.isValid(credentials.email)
                    case .password:
                        self.validationErrors[.password] = self.passwordValidator.isValid(credentials.password)
                        if !credentials.repeatPassword.isEmpty {
                            self.validationErrors[.confirmPassword] = self.passwordValidator.isValid(
                                credentials.password,
                                repeatPassword: credentials.repeatPassword
                            )
                        }
                    case .confirmPassword:
                        let errors: [PasswordValidator.Error] = [
                            self.passwordValidator.isValid(credentials.repeatPassword),
                            self.passwordValidator.isValid(
                                credentials.password,
                                repeatPassword: credentials.repeatPassword
                            )
                        ].compactMap { $0 }
                        self.validationErrors[.confirmPassword] = errors.first
                    default:
                        return
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func validate(
        email: String,
        phone: String,
        password: String,
        repeatPassword: String
    ) -> Bool {
        let gadgetVerified = !email.isEmpty || phoneNumberValidator.isValid(phone)
        let passwordError: PasswordValidator.Error? = passwordValidator.isValid(password, repeatPassword: repeatPassword)
        var passwordVerified = false
        if passwordError == nil {
            passwordVerified = true
        }

        let success = gadgetVerified && passwordVerified

        return success
    }

    func signUpRequest(credentials: Module.Credentials) async -> Bool {
        do {
            let email = credentials.email
            let phone = credentials.phone
            var authMethods: Set<AuthRepositoryImpl.AuthMethod> = .init()
            if !email.isEmpty {
                authMethods.insert(.email(email))
            }
            if !phone.isEmpty {
                let formattedPhone = try phoneNumberFormatter.string(from: phone)
                let trimmedPhone = formattedPhone.trimmingCharacters(in: .symbols)
                authMethods.insert(.phone(trimmedPhone))
            }

            try await authService.signUp(authMethods: authMethods, password: credentials.password)

            return true
        } catch {
            log.debug("error: \(error). \nlocalizedDescription:\(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func signInWithGoogleRequest() async -> Bool {
        typealias Localization = AppLocale.General.Services.Auth

        do {
            _ = try await authService.signInWithGoogle()
            return true
        } catch GoogleAuthServiceImpl.Error.cancelledByUser {
        } catch _ as GoogleAuthServiceImpl.Error {
            await appState.showError(message: Localization.googleAuthFailedMessage)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func signInWithAppleRequest() async -> Bool {
        typealias Localization = AppLocale.General.Services.Auth

        do {
            _ = try await authService.signInWithApple()
            return true
        } catch AppleAuthServiceImpl.Error.cancelledByUser {
        } catch _ as AppleAuthServiceImpl.Error {
            await appState.showError(message: Localization.googleAuthFailedMessage)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func showOTPAlert(credentials: Module.Credentials) -> Bool {
        let email: String = credentials.email
        let phone: String = credentials.phone

        return !email.isEmpty && !phone.isEmpty
    }

    func openOTPScreen(credentials: Module.Credentials, reversed: Bool = false) {
        let email = credentials.email
        let phone = credentials.phone
        var gadgets: [UserModel.GadgetModel] = []

        if !email.isEmpty {
            let emailGadget: UserModel.GadgetModel = .unverified(identifier: email, type: .email)
            gadgets.append(emailGadget)
        }

        if !phone.isEmpty {
            let phoneGadget: UserModel.GadgetModel = .unverified(identifier: phone, type: .phone)
            gadgets.append(phoneGadget)
        }

        if reversed {
            gadgets = gadgets.reversed()
        }

        let screen: Screen = .otp(
            parrentFlow: .singUp(credentials: .password(credentials.password)),
            gadgets: NonEmptyArray(gadgets) ?? NonEmptyArray(.unverified(identifier: "", type: .email))
        )
        appState.navigation[\.path].append(.push(screen))
    }

    func openAuthorizedZone() {
        tokenRegistryService.registerTokens()
        appState.navigation.send(.authorized)
        appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
    }
}
