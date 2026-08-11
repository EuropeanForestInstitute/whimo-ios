//
//  LoginViewModel.swift
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
import Combine
import Utility
import Resources

private typealias Module = LoginModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var credentials: Credentials = .email(username: "", password: "")
        @Published private(set) var isLoginButtonEnabled: Bool = false
        var credentialTypes: IdentifiedArrayOf<CredentialsType> {
            .init(uniqueElements: [
                .email,
                .phone
            ])
        }

        private(set) var validationErrors: [KeyboardField: Error] = [:]

        // MARK: - Private Properties
        private let phoneNumberFormatter: PhoneNumberFormatter = .flat
        private let phoneNumberValidator: PhoneNumberValidator = .shared
        private let emailValidator: EmailValidator = .shared
        private let passwordValidator: PasswordValidator = .shared

        private var cancellable: CancelBag = .init()
        private var keyboardActiveField: KeyboardField?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.authInteractor) private var authInteractor
        @Inject(\.tokenRegistryService) private var tokenRegistryService

        // MARK: - Init
        init() {
            setupBindings()
        }

        // MARK: - ViewModelProtocol
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        func didTapLogin() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            let result = await signInRequest(credentials: credentials)

            guard let result else { return }

            switch result {
                case .verifyGadget:
                    var gadget: UserModel.GadgetModel

                    switch credentials {
                        case .email(let username, _):
                            gadget = .unverified(identifier: username, type: .email)
                        case .phone(let username, _):
                            gadget = .unverified(identifier: username, type: .phone)
                    }

                    let screen: Screen = .otp(
                        parrentFlow: .singUp(credentials: .password(credentials.password)),
                        gadgets: NonEmptyArray(gadget)
                    )
                    appState.navigation[\.path].append(.push(screen))
                    return
                case .success:
                    openAuthorizedZone()
                    return
            }
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

        func flushValidations() {
            validationErrors.removeAll()
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

                let success: Bool
                switch credentials {
                    case .email(let email, let password):
                        success = self.validateEmailCredentials(email: email, password: password)
                    case .phone(let phone, let password):
                        success = self.validatePhoneCredentials(phone: phone, password: password)
                }
                Task { @MainActor in
                    self.isLoginButtonEnabled = success
                }
            }
            .store(in: cancellable)
        $credentials
            .map { (credentials: $0, keyboardActiveField: self.keyboardActiveField) }
            .dropFirst()
            .sink { [weak self] credentials, keyboardActiveField in
                guard let self else { return }

                switch keyboardActiveField {
                    case .username:
                        switch credentials {
                            case .email(let email, _):
                                self.validationErrors[.username] = self.emailValidator.isValid(email)
                            case .phone(let phone, _):
                                self.validationErrors[.username] = self.phoneNumberValidator.isValid(phone)
                        }
                    case .password:
                        self.validationErrors[.password] = self.passwordValidator.isValid(credentials.password)
                    default:
                        return
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func validateEmailCredentials(email: String, password: String) -> Bool {
        let gadgetVerified = emailValidator.isValid(email) == nil
        let passwordVerified = passwordValidator.isValid(password) == nil
        let success = gadgetVerified && passwordVerified

        return success
    }

    func validatePhoneCredentials(phone: String, password: String) -> Bool {
        let gadgetVerified = phoneNumberValidator.isValid(phone) == nil
        let passwordVerified = passwordValidator.isValid(password) == nil
        let success = gadgetVerified && passwordVerified

        return success
    }

    func signInRequest(credentials: Module.Credentials) async -> AuthInteractorImpl.SignInResult? {
        do {
            let contactIdentifier: ContactIdentifier
            switch credentials {
                case .email(let username, _):
                    contactIdentifier = .email(username)
                case .phone(let username, _):
                    let formattedPhone = try phoneNumberFormatter.string(from: username)
                    contactIdentifier = .phone(formattedPhone)
            }

            let result = try await authInteractor.signIn(
                contactIdentifier: contactIdentifier,
                password: credentials.password
            )
            return result
        } catch {
            log.debug("error: \(error). \nlocalizedDescription:\(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
        }

        return nil
    }

    func signInWithGoogleRequest() async -> Bool {
        typealias Localization = AppLocale.General.Services.Auth

        do {
            _ = try await authInteractor.signInWithGoogle()
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
            _ = try await authInteractor.signInWithApple()
            return true
        } catch AppleAuthServiceImpl.Error.cancelledByUser {
        } catch _ as AppleAuthServiceImpl.Error {
            await appState.showError(message: Localization.googleAuthFailedMessage)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func openAuthorizedZone() {
        tokenRegistryService.registerTokens()
        appState.navigation.send(.authorized)
        appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
    }
}
