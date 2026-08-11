//
//  AlertManager+AlertModel.swift
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
import typealias Utility.DomainModel

private typealias AlertModel = AlertManager.AlertModel

// MARK: - AlertModel
extension AlertManager {
    public struct AlertModel: DomainModel {
        // MARK: - ButtonsAxis
        public enum ButtonsAxis {
            case horizontal
            case vertical
        }

        // MARK: - Public Properties
        public let title: String
        public var subtitle: String?
        public var contentView: AnyView?
        public var buttons: [Button]
        public let buttonsAxis: ButtonsAxis

        public var id: Self { self }

        // MARK: - Init
        public init(
            title: String,
            subtitle: String? = nil,
            contentView: AnyView? = nil,
            buttons: [Button] = [],
            buttonsAxis: ButtonsAxis = .horizontal
        ) {
            self.title = title
            self.subtitle = subtitle
            self.contentView = contentView
            self.buttons = buttons
            self.buttonsAxis = buttonsAxis
        }

        // MARK: - Public Methods

        /// Applied buttons overrides default alert buttons.
        public func with(buttons: [Button]) -> Self {
            var copy = self
            copy.buttons = buttons
            return copy
        }

        // MARK: - Equatable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.buttons == rhs.buttons
            && lhs.buttonsAxis == rhs.buttonsAxis
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(subtitle)
            hasher.combine(buttons)
            hasher.combine(buttonsAxis)
        }
    }
}

// MARK: - Button
extension AlertModel {
    public struct Button: DomainModel {
        public typealias Action = (() -> Void)
        public typealias ButtonStyle = AppButton.ButtonStyle

        // MARK: - Public Properties
        public let title: String
        public let style: ButtonStyle
        public var action: Action?

        public var id: Self { self }

        // MARK: - Init
        public init(title: String, style: ButtonStyle = .prominent, action: Action? = nil) {
            self.title = title
            self.style = style
            self.action = action
        }

        // MARK: - Equatable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.title == rhs.title &&
            lhs.style == rhs.style
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(style.hashValue)
        }
    }
}
