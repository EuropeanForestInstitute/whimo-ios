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

// MARK: - RegistrationContactIdentifier
private struct RegistrationContactIdentifier {
    let submittedValue: ContactIdentifier
    let otpGadget: UserModel.GadgetModel
}

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var credentials: Credentials = .empty
        @Published var enableRegisterButton: Bool = false
        @Published private(set) var selectedContactIdentifierType: ContactIdentifierType = .email
        @Published private(set) var phoneVerificationError: PhoneVerificationError?

        var contactIdentifierTypes: IdentifiedArrayOf<ContactIdentifierType> {
            .init(uniqueElements: ContactIdentifierType.allCases)
        }

        private(set) var validationErrors: [KeyboardField: Error] = [:]

        // MARK: - Private Properties
        private let phoneNumberFormatter: PhoneNumberFormatter = .flat
        private let passwordValidator: PasswordValidator = .shared
        private let phoneNumberValidator: PhoneNumberValidator = .shared
        private let emailValidator: EmailValidator = .shared

        private var keyboardActiveField: KeyboardField?
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.authInteractor) private var authInteractor
        @Inject(\.remoteConfigService) private var remoteConfigService
        @Inject(\.tokenRegistryService) private var tokenRegistryService

        // MARK: - Init
        init() {
            setupBindings()
        }

        // MARK: - ViewModelProtocol
        @MainActor
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        @MainActor
        func selectContactIdentifierType(_ contactIdentifierType: ContactIdentifierType) {
            guard selectedContactIdentifierType != contactIdentifierType else { return }

            selectedContactIdentifierType = contactIdentifierType
            keyboardActiveField = nil

            switch contactIdentifierType {
                case .email:
                    validationErrors[.phone] = nil
                    phoneVerificationError = nil
                case .phone:
                    validationErrors[.email] = nil
            }

            updatePhoneVerificationValidation(credentials)
            updateRegisterButton(credentials)
        }

        @MainActor
        func didTapSignUp() async {
            let credentials = credentials
            let contactIdentifierType = selectedContactIdentifierType
            guard
                validate(credentials, for: contactIdentifierType),
                credentials.isTermsAccepted
            else {
                updatePhoneVerificationValidation(credentials)
                return
            }

            let contactIdentifier: RegistrationContactIdentifier
            do {
                contactIdentifier = try makeRegistrationContactIdentifier(
                    credentials: credentials,
                    for: contactIdentifierType
                )
            } catch {
                await reportRegistrationError(error)
                return
            }

            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            let success = await signUpRequest(
                contactIdentifier: contactIdentifier.submittedValue,
                password: credentials.password
            )
            guard success else { return }

            openOTPScreen(
                password: credentials.password,
                gadget: contactIdentifier.otpGadget
            )
        }

        @MainActor
        func didTapGoogleAuth() async {
            let success = await signInWithGoogleRequest()
            guard success else { return }

            openAuthorizedZone()
        }

        @MainActor
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] credentials in
                guard let self else { return }

                self.updatePhoneVerificationValidation(credentials)
                self.updateRegisterButton(credentials)
            }
            .store(in: cancellable)
        $credentials
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] credentials in
                guard let self else { return }

                switch self.keyboardActiveField {
                    case .email:
                        self.validationErrors[.email] = self.emailValidator.isValid(credentials.email)
                    case .phone:
                        self.validationErrors[.phone] = self.phoneNumberValidator.isValid(credentials.phone)
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
        _ credentials: Module.Credentials,
        for contactIdentifierType: Module.ContactIdentifierType
    ) -> Bool {
        let isContactIdentifierValid: Bool
        switch contactIdentifierType {
            case .email:
                isContactIdentifierValid = emailValidator.isValid(credentials.email) == nil
            case .phone:
                let isPhoneValid = phoneNumberValidator.isValid(credentials.phone) == nil
                isContactIdentifierValid = isPhoneValid && !isPhoneVerificationUnavailable(credentials.phone)
        }

        let isPasswordValid = passwordValidator.isValid(credentials.password) == nil
        let isConfirmationValid = passwordValidator.isValid(
            credentials.password,
            repeatPassword: credentials.repeatPassword
        ) == nil

        return isContactIdentifierValid && isPasswordValid && isConfirmationValid
    }

    func updateRegisterButton(_ credentials: Module.Credentials) {
        let isEnabled = validate(
            credentials,
            for: selectedContactIdentifierType
        ) && credentials.isTermsAccepted
        enableRegisterButton = isEnabled
    }

    func updatePhoneVerificationValidation(_ credentials: Module.Credentials) {
        guard
            selectedContactIdentifierType == .phone,
            isPhoneVerificationUnavailable(credentials.phone)
        else {
            phoneVerificationError = nil
            return
        }

        phoneVerificationError = .registrationUnavailable
    }

    func isPhoneVerificationUnavailable(_ phone: String) -> Bool {
        guard !phone.isEmpty, phoneNumberValidator.isValid(phone) == nil else { return false }

        let availability = phoneNumberValidator.verificationAvailability(
            for: phone,
            policy: remoteConfigService.registrationPhoneRegionPolicy
        )
        return availability == .unavailable
    }

    func signUpRequest(
        contactIdentifier: ContactIdentifier,
        password: String
    ) async -> Bool {
        do {
            try await authInteractor.signUp(
                contactIdentifier: contactIdentifier,
                password: password
            )

            return true
        } catch {
            await reportRegistrationError(error)
        }

        return false
    }

    func makeRegistrationContactIdentifier(
        credentials: Module.Credentials,
        for contactIdentifierType: Module.ContactIdentifierType
    ) throws -> RegistrationContactIdentifier {
        switch contactIdentifierType {
            case .email:
                return .init(
                    submittedValue: .email(credentials.email),
                    otpGadget: .unverified(identifier: credentials.email, type: .email)
                )
            case .phone:
                let formattedPhone = try phoneNumberFormatter.string(from: credentials.phone)
                let trimmedPhone = formattedPhone.trimmingCharacters(in: .symbols)
                return .init(
                    submittedValue: .phone(trimmedPhone),
                    otpGadget: .unverified(identifier: credentials.phone, type: .phone)
                )
        }
    }

    func reportRegistrationError(_ error: Error) async {
        log.debug("error: \(error). \nlocalizedDescription:\(error.localizedDescription)")
        await appState.showError(message: error.localizedDescription)
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

    func openOTPScreen(password: String, gadget: UserModel.GadgetModel) {
        let screen: Screen = .otp(
            parrentFlow: .singUp(credentials: .password(password)),
            gadgets: NonEmptyArray(gadget)
        )
        appState.navigation[\.path].append(.push(screen))
    }

    func openAuthorizedZone() {
        tokenRegistryService.registerTokens()
        appState.navigation.send(.authorized)
        appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
    }
}
