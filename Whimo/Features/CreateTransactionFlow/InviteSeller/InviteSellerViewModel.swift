//
//  InviteSellerViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.08.2025.
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
#if canImport(Utility)
import Utility
#endif
#if canImport(CommonUI)
import class CommonUI.AlertManager
import protocol CommonUI.ContactsPermissionsProvider
#endif

private typealias Module = InviteSellerModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var recipient: TransactionType.Recipient = .empty
        private(set) var validationErrors: [KeyboardField: Error] = [:]

        var permissionsProvider: ContactsPermissionsProvider { permissionsService }

        // MARK: - Private Properties
        private let emailValidator: EmailValidator = .shared
        private var cancellable: CancelBag = .init()
        private var keyboardActiveField: KeyboardField?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.permissionsService) private var permissionsService
        @Inject(\.profileRemoteRepository) private var profileRemoteRepository

        // MARK: - Init
        init() {
            setupBinding()
        }

        // MARK: - ViewModelProtocol
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        func didTapConfirm() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            guard
                let contact = recipient.recipientContact,
                !contact.isEmpty
            else { return }

            do {
                let exists = try await profileRemoteRepository.checkGadgetExists(contact)

                if exists {
                    alertManager.show(feature: AlertManager.AlertModel.Features.BuyerExists.self) { [weak self] key in
                        switch key {
                            case .continueInitial:
                                return self?.continueInitialTx
                            case .continueDownstream:
                                return self?.continueDownstreamTx
                        }
                    }
                    return
                }

                continueInitialTx()
            } catch {
                await appState.showError(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.createTransaction.state
            .map { state -> TransactionType.Recipient? in
                switch state.transactionType {
                    case .downstream:
                        return nil
                    case .producer(let seller):
                        switch seller {
                            case .farmer:
                                return nil
                            case .cooperative(let recipient):
                                return recipient
                        }
                    case nil:
                        return nil
                }
            }
            .compactMap { $0 }
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
    func continueInitialTx() {
        appState.createTransaction.dispatch { state in
            switch state.transactionType {
                case .downstream:
                    break
                case .producer(let seller):
                    switch seller {
                        case .farmer:
                            break
                        case .cooperative:
                            state.transactionType = .producer(seller: .cooperative(recipient: self.recipient))
                    }
                case nil:
                    break
            }
        }
        appState.navigation[\.path].removeLast()
    }

    func continueDownstreamTx() {
        appState.createTransaction.dispatch { state in
            switch state.transactionType {
                case .downstream:
                    break
                case .producer(let seller):
                    switch seller {
                        case .farmer:
                            break
                        case .cooperative:
                            state.transactionType = .downstream(action: .buy, recipient: self.recipient)
                            state.farmLocation = nil
                    }
                case nil:
                    break
            }
        }
        appState.navigation[\.path].removeLast()
    }
}
