//
//  CreatePasswordViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 01.05.2025.
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
import Combine
import Utility
import Resources

private typealias Module = CreatePasswordModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var password = ""
        @Published var repeatPassword = ""
        @Published var enableConfirmButton: Bool = false

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        private let otpCode: String
        private let gadgetId: String
        private let passwordValidator: PasswordValidator = .shared

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.authRepository) private var authRepository

        // MARK: - Init
        init() {
            @Inject(\.appState) var appState
            self.gadgetId = appState.createPassword.value.gadgetId
            self.otpCode = appState.createPassword.value.otpCode

            setupBindings()
        }

        deinit {
            appState.createPassword.dispatch { state in
                state.gadgetId = ""
                state.otpCode = ""
            }
        }

        // MARK: - ViewModelProtocol
        func didTapChangePassword() async {
            typealias Localization = AppLocale.CreatePassword.Toast
            if password != repeatPassword {
                await appState.showError(message: Localization.PasswordsMissmatch.message)
                return
            }

            let success = await updatePasswordRequest(gadgetId: gadgetId, password: password, otpCode: otpCode)
            guard success else { return }

            let navigationStackLevel = appState.navigation[\.path].count
            appState.navigation[\.path].removeLast(max(.zero, navigationStackLevel - 1))

            await appState.showInfo(message: Localization.PasswordsUpdated.message)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBindings() {
        Publishers.CombineLatest($password, $repeatPassword)
            .sink { [weak self] password, repeatPassword in
                guard let self else { return }

                let success = self.validate(password: password, repeatPassword: repeatPassword)
                Task { @MainActor in
                    self.enableConfirmButton = success
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func validate(password: String, repeatPassword: String) -> Bool {
        let passwordError: PasswordValidator.Error? = passwordValidator.isValid(
            password,
            repeatPassword: repeatPassword
        )
        if passwordError == nil {
            return true
        }

        return false
    }

    func updatePasswordRequest(gadgetId: String, password: String, otpCode: String) async -> Bool {
        do {
            try await authRepository.verifyPasswordReset(
                gadgetId: gadgetId,
                pass: password,
                code: otpCode
            )

            return true
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }
}
