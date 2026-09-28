//
//  ToastRootView.swift
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
import IdentifiedCollections

// MARK: - ToastRootView
internal struct ToastRootView: View {
    // MARK: - Tuple
    private struct Tuple: Equatable {
        var count: Int
        var isAppeared: Bool
    }

    // MARK: - Dependencies
    @ObservedObject var manager: ToastManager

    // MARK: - Private Properties
    private var models: IdentifiedArrayOf<ToastManager.ToastValue> { manager.isAppeared ? manager.models : [] }
    private var isTop: Bool { manager.position == .top }

    // MARK: - Layout
    var body: some View {
        content()
            .padding([.leading, .trailing], 16)
            .onAppear(perform: manager.onAppear)
    }
}

// MARK: - Private Layout
private extension ToastRootView {
    @ViewBuilder func content() -> some View {
        VStack {
            if !isTop { Spacer() }
            ZStack {
                ForEach(Array(models.enumerated()), id: \.element) { index, model in
                    toastView(manager: manager, index: index, model: model)
                }
            }
            if isTop { Spacer() }
        }
        .animation(
            .spring(duration: ToastManager.Settings.removalAnimationDuration),
            value: Tuple(count: manager.models.count, isAppeared: manager.isAppeared)
        )
    }

    @ViewBuilder func toastView(
        manager: ToastManager,
        index: Int,
        model: ToastManager.ToastValue
    ) -> some View {
        ToastInteractingView(model: model, manager: manager)
            .transformingTransition(
                opacity: 0.0,
                scale: 0.5,
                yOffset: isTop ? -96 : 96
            )
            .padding(
                [isTop ? .top : .bottom],
                // Place front element with bottom offset -32.
                // Other elements stay on the same place
                index != (models.indices.last ?? .zero) ? -(CGFloat(index) + 32) : .zero
            )
            .scaleEffect(
                index != (models.indices.last ?? .zero)
                ? CGSize(width: 0.8, height: 0.8)
                : CGSize(width: 1, height: 1)
            )
    }
}
