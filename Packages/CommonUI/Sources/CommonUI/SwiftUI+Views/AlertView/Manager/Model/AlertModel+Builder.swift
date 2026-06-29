//
//  AlertModel+Builder.swift
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

import Foundation

private typealias AlertModel = AlertManager.AlertModel

// MARK: - Builder
extension AlertModel {
    public enum Builder {
        public typealias AlertModel = AlertManager.AlertModel

        public static func build<F: AlertFeature>(
            feature: F.Type,
            _ action: @escaping (_ key: F.ActionKeys) -> AlertModel.Button.Action?
        ) -> AlertManager.AlertModel {
            var alert = F.alert
            alert.buttons = zip(F.ActionKeys.allCases, alert.buttons).map { key, button in
                var button = button
                button.action = action(key)
                return button
            }
            return alert
        }
    }
}

// MARK: - AlertModel+Builder init
extension AlertModel {
    public init<F: AlertFeature>(
        feature: F.Type,
        _ action: @escaping (_ key: F.ActionKeys) -> AlertManager.AlertModel.Button.Action?
    ) {
        let alert = Builder.build(feature: feature, action)
        self.init(
            title: alert.title,
            subtitle: alert.subtitle,
            buttons: alert.buttons,
            buttonsAxis: alert.buttonsAxis
        )
    }
}
