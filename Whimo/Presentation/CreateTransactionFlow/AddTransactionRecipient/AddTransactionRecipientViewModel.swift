//
//  AddTransactionRecipientViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 11.06.2025.
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
import class CommonUI.AlertManager
import protocol CommonUI.ContactsPermissionsProvider

private typealias Module = AddTransactionRecipientModule
private typealias ViewModel = Module.ViewModel
private typealias ErrorLocalization = AppLocale.AddTransactionRecipient.Error

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        enum RecipientError: LocalizedError {
            case phoneNumberNotExists
            case emailNotExists

            var errorDescription: String? {
                switch self {
                    case .phoneNumberNotExists:
                        ErrorLocalization.phoneNumberNotExists
                    case .emailNotExists:
                        ErrorLocalization.emailNotExists
                }
            }
        }

        // MARK: - Public Properties
        @Published var recipient: TransactionType.Recipient = .empty
        @Published private(set) var isSaveButtonEnabled: Bool = false
        @Published var validationErrors: [KeyboardField: Error] = [:]
        @Published var keyboardActiveField: KeyboardField?

        let action: TransactionModel.Action

        var permissionsProvider: ContactsPermissionsProvider { permissionsService }

        // MARK: - Private Properties
        private let emailValidator: EmailValidator = .shared
        private let phoneNumberValidator: PhoneNumberValidator = .shared
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.permissionsService) private var permissionsService
        @Inject(\.profileRemoteRepository) private var profileRemoteRepository

        // MARK: - Init
        init(action: TransactionModel.Action) {
            self.action = action

            setupBinding()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirm() {
            updateTransactionType(recipient: recipient)
            goBack()
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.createTransaction.state
            .map(\.transactionType)
            .map { transactionType -> TransactionType.Recipient in
                switch transactionType {
                    case .downstream(_, let recipient):
                        return recipient
                    default:
                        return .empty
                }
            }
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.recipient)
            .store(in: cancellable)
        $recipient
            .receive(on: DispatchQueue.main)
            .defaultDebounce()
            .map(\.recipientID)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }

                Task { @MainActor in
                    self.validateSaveButton(recipient: self.recipient)
                }
            }
            .store(in: cancellable)
        $recipient
            .receive(on: DispatchQueue.main)
            .defaultDebounce()
            .map(\.email)
            .combineLatest($keyboardActiveField)
            .removeDuplicates(by: { lhs, rhs in (lhs.0 == rhs.0 && lhs.1 == rhs.1) })
            .scan(
                (recipient.email, keyboardActiveField, keyboardActiveField)
            ) { prev, current -> (
                email: String,
                oldKeyboardActiveField: Module.KeyboardField?,
                keyboardActiveField: Module.KeyboardField?
            ) in
                let value1: String = current.0
                let value2: Module.KeyboardField? = prev.2
                let value3: Module.KeyboardField? = current.1
                return (value1, value2, value3)
            }
            .sink { [weak self] email, oldKeyboardActiveField, keyboardActiveField in
                guard let self else { return }

                Task {
                    await self.validateEmail(email: email, oldKeyboardActiveField: oldKeyboardActiveField, keyboardActiveField: keyboardActiveField)
                    await self.validateSaveButton(recipient: self.recipient)
                }
            }
            .store(in: cancellable)
        $recipient
            .receive(on: DispatchQueue.main)
            .defaultDebounce()
            .map(\.phone)
            .combineLatest($keyboardActiveField)
            .removeDuplicates(by: { lhs, rhs in (lhs.0 == rhs.0 && lhs.1 == rhs.1) })
            .scan(
                (recipient.phone, keyboardActiveField, keyboardActiveField)
            ) { prev, current -> (
                phone: String,
                oldKeyboardActiveField: Module.KeyboardField?,
                keyboardActiveField: Module.KeyboardField?
            ) in
                let value1: String = current.0
                let value2: Module.KeyboardField? = prev.2
                let value3: Module.KeyboardField? = current.1
                return (value1, value2, value3)
            }
            .sink { [weak self] phone, oldKeyboardActiveField, keyboardActiveField in
                guard let self else { return }

                Task {
                    await self.validatePhone(phone: phone, oldKeyboardActiveField: oldKeyboardActiveField, keyboardActiveField: keyboardActiveField)
                    await self.validateSaveButton(recipient: self.recipient)
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func updateTransactionType(recipient: TransactionType.Recipient) {
        let currentState = appState.createTransaction.value.transactionType
        var updatedState: TransactionType?
        if case .downstream(let action, _) = currentState {
            updatedState = .downstream(action: action, recipient: recipient)
        }

        appState.createTransaction[\.transactionType] = updatedState
    }

    func goBack() {
        appState.navigation[\.path].removeLast()
    }

    func isPhoneTaken(_ phone: String) async {
        // skip if inited selling flow
        guard action == .buy else { return }

        let validationError = phoneNumberValidator.isValid(phone)
        guard validationError == nil else { return }

        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        do {
            let exists = try await profileRemoteRepository.checkGadgetExists(phone)
            guard !exists else { return }

            Task { @MainActor in
                validationErrors[.phone] = RecipientError.phoneNumberNotExists
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func isEmailTaken(_ email: String) async {
        // skip if inited selling flow
        guard action == .buy else { return }

        let validationError = emailValidator.isValid(email)
        guard validationError == nil else { return }

        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        do {
            let exists = try await profileRemoteRepository.checkGadgetExists(email)
            guard !exists else { return }

            Task { @MainActor in
                validationErrors[.email] = RecipientError.emailNotExists
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func skipKeyboardField(
        oldValue: AddTransactionRecipientModule.KeyboardField?,
        newValue: AddTransactionRecipientModule.KeyboardField?
    ) -> Bool {
        // skip on keyboard appear
        if oldValue == nil, newValue != nil { return true }

        // skip on keyboard dismiss
        if oldValue != nil, newValue == nil { return true }

        // skip on keyboard field change
        if oldValue != newValue { return true }

        return false
    }

    func validateEmail(
        email: String,
        oldKeyboardActiveField: AddTransactionRecipientModule.KeyboardField?,
        keyboardActiveField: AddTransactionRecipientModule.KeyboardField?,
    ) async {
        log.debug()

        @MainActor
        func validate(email: String) {
            self.validationErrors[.email] = email.isEmpty
            ? nil
            : self.emailValidator.isValid(email)
        }

        let skip = skipKeyboardField(oldValue: oldKeyboardActiveField, newValue: keyboardActiveField)
        guard !skip else { return }

        await validate(email: email)
        if self.validationErrors[.email] == nil {
            await self.isEmailTaken(email)
        }
    }

    func validatePhone(
        phone: String,
        oldKeyboardActiveField: AddTransactionRecipientModule.KeyboardField?,
        keyboardActiveField: AddTransactionRecipientModule.KeyboardField?,
    ) async {
        log.debug()

        @MainActor
        func validate(phone: String) {
            self.validationErrors[.phone] = phone.isEmpty
            ? nil
            : self.phoneNumberValidator.isValid(phone)
        }

        let skip = skipKeyboardField(oldValue: oldKeyboardActiveField, newValue: keyboardActiveField)
        guard !skip else { return }

        await validate(phone: phone)
        if self.validationErrors[.phone] == nil {
            await self.isPhoneTaken(phone)
        }
    }

    @MainActor
    func validateSaveButton(recipient: TransactionType.Recipient) {
        log.debug()

        func validate(
            recipientID: String,
            email: String,
            phone: String
        ) -> Bool {
            let recipientIDVerified = !recipientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let emailVerified = !email.isEmpty && validationErrors[.email] == nil
            let phoneVerified = !phone.isEmpty && validationErrors[.phone] == nil
            let success = recipientIDVerified || emailVerified || phoneVerified

            return success
        }

        let fieldsSuccess = validate(
            recipientID: recipient.recipientID,
            email: recipient.email,
            phone: recipient.phone
        )
        let success = fieldsSuccess
        self.isSaveButtonEnabled = success
    }
}
