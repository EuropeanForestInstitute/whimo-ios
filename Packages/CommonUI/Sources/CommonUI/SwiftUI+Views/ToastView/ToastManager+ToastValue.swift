//
//  ToastManager+ToastValue.swift
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

import Foundation
import SwiftUI

extension ToastManager {
    // MARK: - ToastValue
    public struct ToastValue: Identifiable, Hashable {
        public let id: UUID = .init()

        public var icon: AnyView?
        public var message: String
        public var button: ToastButton?
        /// If nil, the toast will persist and not disappear. Used when displaying a loading toast.
        public var duration: TimeInterval?

        public init(
            icon: (any View)? = nil,
            message: String,
            button: ToastButton? = nil,
            duration: TimeInterval = 3.0
        ) {
            self.icon = icon.map { AnyView($0) }
            self.message = message
            self.button = button
            self.duration = min(max(0, duration), 10)
        }

        @_disfavoredOverload
        internal init(
            icon: (any View)? = nil,
            message: String,
            button: ToastButton? = nil,
            duration: TimeInterval? = nil
        ) {
            self.icon = icon.map { AnyView($0) }
            self.message = message
            self.button = button
            self.duration = duration
        }

        // MARK: - Equatable
        public static func == (lhs: ToastValue, rhs: ToastValue) -> Bool {
            lhs.message == rhs.message &&
            lhs.button == rhs.button &&
            lhs.duration == rhs.duration &&
            lhs.id == rhs.id
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(message)
            hasher.combine(button)
            hasher.combine(duration)
        }
    }

    // MARK: - ToastButton
    public struct ToastButton: Identifiable, Hashable {
        public let id: UUID = .init()
        public var title: String
        public var color: Color
        public var action: () -> Void

        public init(
            title: String,
            color: Color = .primary,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.color = color
            self.action = action
        }

        // MARK: - Equatable
        public static func == (lhs: ToastButton, rhs: ToastButton) -> Bool {
            lhs.title == rhs.title &&
            lhs.color == rhs.color &&
            lhs.id == rhs.id
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(title)
            hasher.combine(color)
        }
    }
}
