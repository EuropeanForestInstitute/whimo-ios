//
//  ToastManager.swift
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
import Extensions
import Utility

// MARK: - ToastManager
@MainActor
public final class ToastManager: ObservableObject {
    // MARK: - Settings
    internal enum Settings {
        static let removalAnimationDuration: Double = 0.3
    }

    // MARK: - ToastPosition
    public enum ToastPosition {
        case top
        case bottom
    }

    // MARK: - Properties
    @Published internal var position: ToastPosition = .top
    @Published internal private(set) var models: IdentifiedArrayOf<ToastValue> = .init()
    @Published internal private(set) var isAppeared = false

    internal var isPresented: Bool {
        !models.isEmpty || isAppeared
    }

    // MARK: - Private Properties
    private var dismissOverlayTask: Task<Void, any Error>?

    // MARK: - Init
    public nonisolated init() {}

    // MARK: - Methods
    internal func onAppear() {
        isAppeared = true
    }

    @discardableResult
    public func append(_ toast: ToastValue) -> ToastValue {
        dismissOverlayTask?.cancel()
        dismissOverlayTask = nil
        models.append(toast)
        return toast
    }

    @discardableResult
    public func append<V>(
        message: String,
        task: () async throws -> V,
        onSuccess: (V) -> ToastValue,
        onFailure: (any Error) -> ToastValue
    ) async throws -> V {
        let model = append(ToastValue(icon: ToastRootView.LoadingView(), message: message, duration: nil))
        do {
            let value = try await task()
            withAnimation(.spring) {
                let updated = onSuccess(value)
                replaceModels(oldModel: model, with: updated)
            }
            return value
        } catch {
            withAnimation(.spring) {
                let updated = onFailure(error)
                replaceModels(oldModel: model, with: updated)
            }
            throw error
        }
    }

    @discardableResult
    public func replace(old oldToast: ToastValue?, new newToast: ToastValue) -> ToastValue {
        if let oldToast = oldToast {
            replaceModels(oldModel: oldToast, with: newToast)
        } else {
            return append(newToast)
        }
        return newToast
    }

    internal func remove(_ model: ToastValue) {
        log.debug("<--- model: \(model)")
        self.models.remove(id: model.id)
        if models.isEmpty {
            dismissOverlayTask = Task {
                try await Task.sleep(seconds: Settings.removalAnimationDuration)
                isAppeared = false
            }
        }
    }

    internal func startRemovalTask(for model: ToastValue) async {
        if let duration = model.duration {
            do {
                try await Task.sleep(seconds: duration)
                remove(model)
            } catch {}
        }
    }
}

// MARK: - Private Methods
private extension ToastManager {
    @discardableResult
    func replaceModels(oldModel: ToastValue, with updatedModel: ToastValue) -> Bool {
        guard let index = self.models.index(id: oldModel.id) else { return false }

        self.models[index] = updatedModel
        return true
    }
}
