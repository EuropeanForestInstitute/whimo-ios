//
//  AppStateImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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
import class CommonUI.ToastManager

final class AppStateImpl: AppState {
    // MARK: - Properties
    let system: StateStore<SystemState>
    let navigation: StateStore<NavigationState>
    let transactions: StateStore<TransactionsState>
    let balance: StateStore<BalanceState>
    let createTransaction: StateStore<CreateTransactionState>
    let createPassword: StateStore<CreatePasswordState>
    let notifications: StateStore<NotificationsState>
    let notificationsSettings: StateStore<NotificationsSettingsState>
    let profile: StateStore<ProfileState>

    // MARK: - Private Dependencies
    private let toastPlugin: ToastPlugin

    init(
        system: StateStore<SystemState>,
        navigation: StateStore<NavigationState>,
        transactions: StateStore<TransactionsState>,
        balance: StateStore<BalanceState>,
        createTransaction: StateStore<CreateTransactionState>,
        createPassword: StateStore<CreatePasswordState>,
        notifications: StateStore<NotificationsState>,
        notificationsSettings: StateStore<NotificationsSettingsState>,
        profile: StateStore<ProfileState>,
        toastManager: ToastManager,
        hapticsEngineService: HapticsEngineServiceProtocol
    ) {
        self.system = system
        self.navigation = navigation
        self.transactions = transactions
        self.balance = balance
        self.createTransaction = createTransaction
        self.createPassword = createPassword
        self.notifications = notifications
        self.notificationsSettings = notificationsSettings
        self.profile = profile
        self.toastPlugin = .init(toastManager: toastManager, hapticsEngineService: hapticsEngineService)
    }

    // MARK: - AppStateContainer
    func showInfo(message: String, hapticsEnabled: Bool) {
        Task { @MainActor in
            await showInfo(message: message, hapticsEnabled: hapticsEnabled)
        }
    }
    @MainActor
    func showInfo(message: String, hapticsEnabled: Bool) async {
        toastPlugin.showInfo(message: message, hapticsEnabled: hapticsEnabled)
    }

    @MainActor @discardableResult
    func replace(old oldToast: ToastValue?, new newToast: ToastValue, hapticsEnabled: Bool) async -> ToastValue {
        toastPlugin.replace(old: oldToast, new: newToast, hapticsEnabled: hapticsEnabled)
    }

    func showError(message: String, button: ToastManager.ToastButton? = nil, hapticsEnabled: Bool = true) {
        Task { @MainActor in
            await showError(message: message, button: button, hapticsEnabled: hapticsEnabled)
        }
    }
    @MainActor
    func showError(message: String, button: ToastManager.ToastButton? = nil, hapticsEnabled: Bool = true) async {
        toastPlugin.showError(message: message, button: button, hapticsEnabled: hapticsEnabled)
    }
}
