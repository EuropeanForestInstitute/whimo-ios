//
//  Notifications+RowData.swift
//  Whimo
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
import Utility

private typealias Module = NotificationsModule

// MARK: - RowData
extension Module {
    struct RowData: DomainModel {
        // MARK: - Properties
        var id: String { rowType.rawValue }
        let rowType: NotificationsModule.Row
        var isEnabled: Bool

        // MARK: - Init
        init(rowType: NotificationsModule.Row, isEnabled: Bool) {
            self.rowType = rowType
            self.isEnabled = isEnabled
        }

        init(from model: NotificationsSettingsModel) {
            self.init(rowType: .init(from: model.type), isEnabled: model.isEnabled)
        }

        // MARK: - Static Builders
        static func defaultOption(isEnabled: Bool) -> RowData {
            .init(rowType: .allowNotifications, isEnabled: isEnabled)
        }

        static func toArray(_ models: IdentifiedArrayOf<NotificationsSettingsModel>) -> IdentifiedArrayOf<Self> {
            .init(uniqueElements: models.elements.map(self.init))
        }

        static func toDomain(_ array: IdentifiedArrayOf<Self>) -> IdentifiedArrayOf<NotificationsSettingsModel> {
            .init(uniqueElements: array
                .elements
                .map { model -> NotificationsSettingsModel? in
                    guard let rowType = model.rowType.toSettingType else { return nil }

                    return .init(type: rowType, isEnabled: model.isEnabled)
                }
                .compactMap { $0 }
            )
        }
    }
}
