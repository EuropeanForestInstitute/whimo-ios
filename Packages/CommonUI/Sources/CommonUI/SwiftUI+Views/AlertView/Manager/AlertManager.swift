//
//  AlertManager.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 09.05.2025.
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

public final class AlertManager: ObservableObject {
    // MARK: - Settings
    internal enum Settings {
        static let removalAnimationDuration: Double = 0.23
    }

    @Published internal private(set) var models: IdentifiedArrayOf<AlertModel> = .init()
    @Published internal private(set) var isAppeared = false

    internal var isPresented: Bool { !models.isEmpty || isAppeared }

    // MARK: - Private Properties
    private var dismissOverlayTask: Task<Void, any Error>?

    public init() { }

    // MARK: - Methods
    internal func onAppear() {
        isAppeared = true
    }

    public func show(_ alert: AlertModel) {
        Task { @MainActor in
            dismissOverlayTask?.cancel()
            dismissOverlayTask = nil
            _ = models.append(alert)
        }
    }

    public func show<F: AlertFeature>(
        feature: F.Type,
        _ action: @escaping (_ key: F.ActionKeys) -> AlertManager.AlertModel.Button.Action?
    ) {
        show(.init(feature: feature, action))
    }

    public func close() {
        Task { @MainActor in
            models.removeLast()
            if models.isEmpty {
                dismissOverlayTask = Task {
                    try await Task.sleep(seconds: Settings.removalAnimationDuration)
                    isAppeared = false
                }
            }
        }
    }
}
