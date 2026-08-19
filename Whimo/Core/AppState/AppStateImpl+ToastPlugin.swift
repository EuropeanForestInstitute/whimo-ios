//
//  AppStateImpl+ToastPlugin.swift
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
import SwiftUI
import class CommonUI.ToastManager
import enum Resources.AppAssets

// MARK: - ToastPlugin
extension AppStateImpl {
    final class ToastPlugin {
        private enum Constants {
            static let infoIcon: Image = AppAssets.Toast.infoCircle
            static let errorIcon: Image = AppAssets.Toast.exclamationMarkTriangle
        }

        typealias ToastValue = ToastManager.ToastValue

        // MARK: - Private Dependencies
        private let toastManager: ToastManager
        private let hapticsEngineService: HapticsEngineServiceProtocol

        // MARK: - Init
        init(toastManager: ToastManager, hapticsEngineService: HapticsEngineServiceProtocol) {
            self.toastManager = toastManager
            self.hapticsEngineService = hapticsEngineService
        }

        // MARK: - Methods
        @MainActor
        func showInfo(message: String, hapticsEnabled: Bool) {
            _showInfo(message: message)
            if hapticsEnabled {
                Task { await hapticsEngineService.produceHaptic() }
            }
        }

        @MainActor
        func showError(message: String, button: ToastManager.ToastButton? = nil, hapticsEnabled: Bool) {
            _showError(message: message, button: button)
            if hapticsEnabled {
                Task { await hapticsEngineService.produceHaptic() }
            }
        }

        @MainActor @discardableResult
        func replace(old oldToast: ToastValue?, new newToast: ToastValue, hapticsEnabled: Bool) -> ToastValue {
            let model = _replace(old: oldToast, new: newToast)
            if hapticsEnabled {
                Task { await hapticsEngineService.produceHaptic() }
            }
            return model
        }
    }
}

// MARK: - Private Methods
private extension AppStateImpl.ToastPlugin {
    @MainActor @discardableResult
    func _showInfo(message: String) -> ToastValue { // swiftlint:disable:this identifier_name
        toastManager.append(.init(icon: Constants.infoIcon, message: message))
    }

    @MainActor @discardableResult
    func _showError(message: String, button: ToastManager.ToastButton?) -> ToastValue { // swiftlint:disable:this identifier_name
        toastManager.append(.init(icon: Constants.errorIcon, message: message, button: button))
    }

    @MainActor @discardableResult
    func _replace(old oldToast: ToastValue?, new newToast: ToastValue) -> ToastValue { // swiftlint:disable:this identifier_name
        toastManager.replace(old: oldToast, new: newToast)
    }
}
