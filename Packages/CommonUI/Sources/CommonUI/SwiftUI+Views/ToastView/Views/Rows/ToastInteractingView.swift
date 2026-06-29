//
//  ToastInteractingView.swift
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
import var Utility.log

private typealias RootView = ToastRootView
private typealias ToastInteractingView = RootView.ToastInteractingView

// MARK: - ToastInteractingView
extension RootView {
    internal struct ToastInteractingView: View {
        // MARK: - Dependencies
        let model: ToastManager.ToastValue
        @ObservedObject var manager: ToastManager

        // MARK: - Private Properties
        @GestureState private var yOffset: CGFloat?
        @State private var dismissTask: Task<Void, any Error>?
        @MainActor
        private var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0)
                .updating($yOffset) { value, state, _ in
                    let translation = value.translation.height
                    if model.duration == nil {
                        state = translation * 0.5
                    } else {
                        let isTopPosition = manager.position == .top
                        let shouldReduceTranslation = (isTopPosition && translation > 0) || (!isTopPosition && translation < 0)
                        state = shouldReduceTranslation ? translation * 0.5 : translation
                    }
                }
                .onEnded { value in
                    if model.duration == nil { return }
                    let threshold: CGFloat = 48 / 2
                    let draggedAmount = manager.position == .top ? -value.translation.height : value.translation.height
                    if draggedAmount > threshold {
                        manager.remove(model)
                    } else {
                        startDismissTask()
                    }
                }
        }
        private var isDragging: Bool { yOffset != nil }

        // MARK: - Layout
        var body: some View {
            content()
                ._onChange(of: isDragging) { _, newValue in
                    if newValue {
                        dismissTask?.cancel()
                        dismissTask = nil
                    }
                }
                ._onChange(of: model.duration == nil, initial: true) { _, _ in
                    startDismissTask()

                    log.debug("---> model: \(model)")
                }
        }
    }
}

// MARK: - Private Layout
private extension ToastInteractingView {
    @ViewBuilder func content() -> some View {
        ToastRootView.ToastView(model: model)
            .offset(y: yOffset ?? 0)
            .simultaneousGesture(dragGesture)
            .animation(.spring, value: isDragging)
            .animation(.easeInOut(duration: 0.1), value: yOffset)
    }
}

// MARK: - Private Methods
private extension ToastInteractingView {
    func startDismissTask() {
        dismissTask?.cancel()
        dismissTask = Task {
            await manager.startRemovalTask(for: model)
        }
    }
}
