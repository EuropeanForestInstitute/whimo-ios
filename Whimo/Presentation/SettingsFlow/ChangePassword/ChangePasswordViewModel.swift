//
//  ChangePasswordViewModel.swift
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

import Foundation
import Utility

private typealias Module = ChangePasswordModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var credentials: Credentials = .empty
        @Published var enableSaveButton: Bool = false

        private var keyboardActiveField: KeyboardField?
        private(set) var validationErrors: [KeyboardField: PasswordValidator.Error] = [:]

        // MARK: - Private Properties
        private let passwordValidator: PasswordValidator = .shared

        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.profileCachingRepository) private var profileCachingRepository

        // MARK: - Init
        init() {
            setupBindings()
        }

        // MARK: - ViewModelProtocol
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        func didTapSave() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            let success = await changePasword(
                currentPassword: credentials.currentPassword,
                newPassword: credentials.password
            )
            guard success else { return }

            await appState.showInfo(message: "Password successfully changed.")
            goBack()
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
                    password: credentials.password,
                    repeatPassword: credentials.repeatPassword
                )
                Task { @MainActor in
                    self.enableSaveButton = fieldsSuccess
                }
            }
            .store(in: cancellable)
        $credentials
            .dropFirst()
            .map(\.password)
            .map(passwordValidator.isValid)
            .sink { [weak self] error in
                guard
                    let self,
                    self.keyboardActiveField == .password
                else { return }

                self.validationErrors[.password] = error
            }
            .store(in: cancellable)
        $credentials
            .dropFirst()
            .map { [weak self] in self?.passwordValidator.isValid($0.password, repeatPassword: $0.repeatPassword) }
            .sink { [weak self] error in
                guard
                    let self,
                    self.keyboardActiveField == .confirmPassword
                else { return }

                self.validationErrors[.confirmPassword] = error
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func validate(password: String, repeatPassword: String) -> Bool {
        let passwordError: PasswordValidator.Error? = passwordValidator.isValid(password, repeatPassword: repeatPassword)
        var passwordVerified = false
        if passwordError == nil {
            passwordVerified = true
        }

        let success = passwordVerified

        return success
    }

    func changePasword(currentPassword: String, newPassword: String) async -> Bool {
        do {
            try await profileCachingRepository.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            return true
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func goBack() {
        appState.navigation[\.path].removeLast()
    }
}
