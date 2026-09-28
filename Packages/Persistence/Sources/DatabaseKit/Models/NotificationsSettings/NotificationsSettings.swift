//
//  NotificationsSettings.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 02.07.2025.
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
import GRDB

// MARK: - NotificationsSettings
public struct NotificationsSettings: Identifiable {
    public let id: String
    public let type: SettingsType
    public var isEnabled: Bool

    public init(
        type: SettingsType,
        isEnabled: Bool
    ) {
        self.id = type.rawValue
        self.type = type
        self.isEnabled = isEnabled
    }
}

// MARK: - NotificationsSettings+Record
extension NotificationsSettings: StorePersistable {
    public static var databaseTableName: String { "notificationsSettings" }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let type = Column(CodingKeys.type)
        public static let isEnabled = Column(CodingKeys.isEnabled)
    }
}

// MARK: - SettingsType
extension NotificationsSettings {
    public enum SettingsType: String, StoreConvertible {
        case geodataMissing
        case geodataUpdated
        case transactionAccepted
        case transactionExpired
        case transactionPending
        case transactionRejected
    }
}

// MARK: - NotificationsSettings+Request
extension NotificationsSettings {
    public static func allSorted() -> QueryInterfaceRequest<Self> {
        NotificationsSettings
            .all()
            .order(\.type.asc)
    }
}
