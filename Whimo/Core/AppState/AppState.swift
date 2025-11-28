//
//  AppState.swift
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

protocol AppState: AnyObject {
    typealias ToastValue = ToastManager.ToastValue

    var system: StateStore<SystemState> { get }
    var navigation: StateStore<NavigationState> { get }
    var transactions: StateStore<TransactionsState> { get }
    var balance: StateStore<BalanceState> { get }
    var createTransaction: StateStore<CreateTransactionState> { get }
    var createPassword: StateStore<CreatePasswordState> { get }
    var notifications: StateStore<NotificationsState> { get }
    var notificationsSettings: StateStore<NotificationsSettingsState> { get }
    var profile: StateStore<ProfileState> { get }

    func showInfo(message: String, hapticsEnabled: Bool)
    @MainActor
    func showInfo(message: String, hapticsEnabled: Bool) async

    @MainActor @discardableResult
    func replace(old oldToast: ToastValue?, new newToast: ToastValue, hapticsEnabled: Bool) async -> ToastValue

    func showError(message: String, button: ToastManager.ToastButton?, hapticsEnabled: Bool)
    @MainActor
    func showError(message: String, button: ToastManager.ToastButton?, hapticsEnabled: Bool) async
}

extension AppState {
    func showInfo(message: String) {
        showInfo(message: message, hapticsEnabled: true)
    }
    @MainActor
    func showInfo(message: String) async {
        await showInfo(message: message, hapticsEnabled: true)
    }

    @MainActor @discardableResult
    func replace(old oldToast: ToastValue?, new newToast: ToastValue) async -> ToastValue {
        await replace(old: oldToast, new: newToast, hapticsEnabled: true)
    }

    func showError(message: String) {
        showError(message: message, button: nil, hapticsEnabled: true)
    }
    func showError(message: String, button: ToastManager.ToastButton?) {
        showError(message: message, button: button, hapticsEnabled: true)
    }
    @MainActor
    func showError(message: String) async {
        await showError(message: message, button: nil, hapticsEnabled: true)
    }
    @MainActor
    func showError(message: String, button: ToastManager.ToastButton) async {
        await showError(message: message, button: button, hapticsEnabled: true)
    }
}
