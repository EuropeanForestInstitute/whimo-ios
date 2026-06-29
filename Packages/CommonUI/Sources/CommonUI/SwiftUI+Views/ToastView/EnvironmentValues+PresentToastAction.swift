//
//  EnvironmentValues+PresentToastAction.swift
//  CommonUI
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

import SwiftUI

extension EnvironmentValues {
    public internal(set) var presentToast: PresentToastAction {
        get { self[PresentToastKey.self] }
        set { self[PresentToastKey.self] = newValue }
    }
}

public struct PresentToastAction {
    // swiftlint:disable:next identifier_name
    internal weak var _manager: ToastManager?
    private var manager: ToastManager {
        // swiftlint:disable:next identifier_name
        guard let _manager else {
            fatalError("View.installToast must be called on a parent view to use EnvironmentValues.presentToast.")
        }
        return _manager
    }

    @MainActor
    public func callAsFunction(_ toast: ToastManager.ToastValue) {
        manager.append(toast)
    }

    @MainActor
    public func callAsFunction(old oldToast: ToastManager.ToastValue?, new newToast: ToastManager.ToastValue) -> ToastManager.ToastValue {
        manager.replace(old: oldToast, new: newToast)
    }

    public func callAsFunction<V>(
        message: String,
        task: () async throws -> V,
        onSuccess: (V) -> ToastManager.ToastValue,
        onFailure: (any Error) -> ToastManager.ToastValue
    ) async throws -> V {
        try await manager.append(
            message: message,
            task: task,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }
}

private enum PresentToastKey: EnvironmentKey {
    static let defaultValue: PresentToastAction = .init()
}
