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
        var credentialTypes: IdentifiedArrayOf<Credentials> {
            .init(uniqueElements: [
                .email(username: "", password: ""),
                .phone(username: "", password: "")
            ])
        }

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        private let phoneNumberFormatter: PhoneNumberFormatter = .flat
        private let passwordValidator: PasswordValidator = .shared

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
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBindings() {
        $credentials
            .sink { [weak self] credentials in
                guard let self else { return }

                let success = self.validate(gadget: credentials.username, password: credentials.password)
                Task { @MainActor in
                    self.isLoginButtonEnabled = success
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func validate(gadget: String, password: String) -> Bool {
        let gadgetVerified = !gadget.isEmpty
        let passwordError: PasswordValidator.Error? = passwordValidator.isValid(password)
        var passwordVerified = false
        if passwordError == nil {
            passwordVerified = true
        }

        let success = gadgetVerified && passwordVerified

        return success
    }

    func signInRequest(credentials: Module.Credentials) async -> AuthServiceImpl.SignInResult? {
        do {
            let authMethod: AuthRepositoryImpl.AuthMethod
            switch credentials {
                case .email(let username, _):
                    authMethod = .email(username)
                case .phone(let username, _):
                    let formattedPhone = try phoneNumberFormatter.string(from: username)
                    authMethod = .phone(formattedPhone)
            }

            let result = try await authService.signIn(authMethod: authMethod, password: credentials.password)
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

    func openAuthorizedZone() {
        tokenRegistryService.registerTokens()
        appState.navigation.send(.authorized)
        appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
    }
}
