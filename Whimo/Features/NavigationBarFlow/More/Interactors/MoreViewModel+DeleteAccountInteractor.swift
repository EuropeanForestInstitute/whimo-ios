//
//  MoreViewModel+DeleteAccountInteractor.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 09.07.2025.
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

private typealias Module = MoreModule
private typealias ViewModel = Module.ViewModel
private typealias DeleteAccountInteractorProtocol = Module.DeleteAccountInteractorProtocol
private typealias DeleteAccountInteractor = Module.ViewModel.DeleteAccountInteractor

// MARK: - DeleteAccountInteractor
extension ViewModel {
    final class DeleteAccountInteractor: DeleteAccountInteractorProtocol {
        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.authService) private var authService
        @Inject(\.dataCleanerService) private var dataCleanerService

        // MARK: - DeleteAccountInteractorProtocol
        func deleteAccount() {
            Task { [weak self] in
                guard let self else { return }

                self.appState.system[\.isLoading] = true
                defer { self.appState.system[\.isLoading] = false }

                do {
                    try await self.authService.deleteAccount()
                    try? await self.dataCleanerService.dropAll()
                    self.openLoginScreen()
                } catch {
                    await self.appState.showError(message: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension DeleteAccountInteractor {
    func openLoginScreen() {
        self.appState.navigation.dispatch { state in
            state.path = [.root(.login, embedInNavigationView: true)]
        }
    }
}
