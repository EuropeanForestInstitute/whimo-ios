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
import class CommonUI.AlertManager
import protocol CommonUI.ContactsPermissionsProvider

private typealias Module = AddTransactionRecipientModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var recipient: TransactionType.Recipient = .empty

        let action: TransactionModel.Action
        private(set) var validationErrors: [KeyboardField: Error] = [:]

        var permissionsProvider: ContactsPermissionsProvider { permissionsService }

        // MARK: - Private Properties
        private let emailValidator: EmailValidator = .shared
        private var cancellable: CancelBag = .init()
        private var keyboardActiveField: KeyboardField?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.permissionsService) private var permissionsService

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

        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
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
            .map(\.email)
            .sink { [weak self] email in
                guard
                    let self,
                    self.keyboardActiveField == .email
                else { return }

                if !email.isEmpty {
                    self.validationErrors[.email] = self.emailValidator.isValid(email)
                } else {
                    self.validationErrors[.email] = nil
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
}
