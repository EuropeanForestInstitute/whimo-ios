//
//  InstallToastModifier.swift
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
import WindowOverlay
import Extensions

// MARK: - InstallToastView
private struct InstallToastView: View {
    @ObservedObject var manager: ToastManager
    var body: some View {
        if manager.isPresented {
            Color.clear
                .windowOverlay(isPresented: true) {
                    ToastRootView(manager: manager)
                }
        }
    }
}

// MARK: - InstallToastModifier
private struct InstallToastModifier: ViewModifier {
    var position: ToastManager.ToastPosition
    @State private var manager: ToastManager

    init(position: ToastManager.ToastPosition, manager: ToastManager) {
        self.position = position
        self.manager = manager
    }

    func body(content: Content) -> some View {
        content
            .environment(
                \.presentToast,
                 PresentToastAction(_manager: manager)
            )
            .background {
                InstallToastView(manager: manager)
            }
            ._onChange(of: position, initial: true) {
                manager.position = $1
            }
    }
}

// MARK: - View+InstallToastModifier
extension View {
    public func installToast(position: ToastManager.ToastPosition = .bottom, manager: ToastManager = .init()) -> some View {
        self.modifier(InstallToastModifier(position: position, manager: manager))
    }
}
