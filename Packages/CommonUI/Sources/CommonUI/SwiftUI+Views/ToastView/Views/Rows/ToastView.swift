//
//  ToastView.swift
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

private typealias RootView = ToastRootView
private typealias ToastView = RootView.ToastView

// MARK: - ToastView
extension RootView {
    internal struct ToastView: View {
        // MARK: - Dependencies
        let model: ToastManager.ToastValue
        @Environment(\.colorScheme) private var colorScheme

        // MARK: - Private Properties
        private var isDark: Bool { colorScheme == .dark }

        // MARK: - Layout
        var body: some View {
            content()
                .compositingGroup()
                .shadow(
                    color: .primary.opacity(isDark ? 0.0 : 0.1),
                    radius: 16,
                    y: 8.0
                )
        }
    }
}

// MARK: - Private Layout
private extension ToastView {
    @ViewBuilder func content() -> some View {
        ZStack {
            // need to be hidden for clear animations inside root view
            toastContentView()
                .hidden()
            // visible toast view
            toastContentView()
                .transformingTransition(opacity: -1)
                .id(model.message)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.toastBackground)
                }
        }
    }

    @ViewBuilder func toastContentView() -> some View {
        HStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                iconView()
                Text(model.message)
                    .lineLimit(3)
                    .padding(.vertical, 16)
            }
            buttonView()
        }
        .font(.system(size: 16, weight: .medium))
    }

    @ViewBuilder func iconView() -> some View {
        if let icon = model.icon {
            icon
                .frame(width: 19, height: 19)
                .padding(.leading, 15)
        } else {
            Color.clear
                .frame(width: 14, height: .zero)
        }
    }

    @ViewBuilder func buttonView() -> some View {
        if let button = model.button {
            buttonView(button)
                .padding([.trailing], 10)
        } else {
            Color.clear
                .frame(width: 14, height: .zero)
        }
    }

    @ViewBuilder func buttonView(_ button: ToastManager.ToastButton) -> some View {
        Button {
            button.action()
        } label: {
            ZStack {
                Capsule()
                    .fill(button.color.opacity(isDark ? 0.15 : 0.07))
                Text(button.title)
                    .foregroundStyle(button.color)
                    .padding(.horizontal, 9)
                    .padding(6)
            }
            .fixedSize(horizontal: true, vertical: true)
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17.0, *)
#Preview {
    let group = VStack {
        ToastView(
            model: .init(
                icon: Image(systemName: "info.circle"),
                message: "Location service cannot pick location. Please grant location access. Bla-bla-blablabla....",
                button: .init(title: "Action", color: .red, action: {})
            )
        )
        ToastView(
            model: .init(
                icon: Image(systemName: "info.circle"),
                message: "This is a toast message",
                button: .init(title: "Action", action: {})
            )
        )
        ToastView(
            model: .init(
                icon: Image(systemName: "info.circle"),
                message: "This is a toast message",
                button: nil
            )
        )
        ToastView(
            model: .init(
                icon: nil,
                message: "This is a toast message",
                button: nil
            )
        )
        ToastView(
            model: .init(
                icon: nil,
                message: "Copied",
                button: nil
            )
        )
    }
    return VStack {
        group
        group
            .padding(20)
            .background {
                Color.black
            }
            .environment(\.colorScheme, .dark)
    }
}
