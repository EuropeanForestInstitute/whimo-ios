//
//  MoreViewModel.swift
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

import SwiftUI
import Utility
import class CommonUI.AlertManager
import enum Resources.LocalizeKeys

private typealias Module = MoreModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        var list: IdentifiedArrayOf<Row> { .init(uniqueElements: Row.allCases) }
        var appVersion: String { userAgentService.appVersion }
        var appBuild: String { userAgentService.appBuild }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.userAgentService) private var userAgentService

        private let logoutInteractor: LogoutInteractorProtocol
        private let deleteAccountInteractor: DeleteAccountInteractorProtocol

        // MARK: - Init
        init() {
            self.logoutInteractor = LogoutInteractor()
            self.deleteAccountInteractor = DeleteAccountInteractor()
        }

        // MARK: - ViewModelProtocol
        func didTapLogout() {
            alertManager.show(feature: AlertManager.AlertModel.Features.Logout.self) { [weak self] key in
                switch key {
                    case .cancel:
                        return nil
                    case .logout:
                        return self?.logoutInteractor.logout
                }
            }
        }

        func didTapDeleteAccount() {
            alertManager.show(feature: AlertManager.AlertModel.Features.DeleteAccount.self) { [weak self] key in
                switch key {
                    case .cancel:
                        return nil
                    case .delete:
                        return self?.deleteAccountInteractor.deleteAccount
                }
            }
        }

        func didTapLegalInformation() {
            alertManager.show(feature: AlertManager.AlertModel.Features.InDevelopment.self) { _ in nil }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel { }
