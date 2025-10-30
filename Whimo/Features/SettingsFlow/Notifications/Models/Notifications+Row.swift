//
//  Notifications+Row.swift
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

import SwiftUI
import typealias Utility.DomainModel
import Resources

private typealias Module = NotificationsModule
private typealias Localization = AppLocale.Notifications.Row

// MARK: - Row
extension Module {
    enum Row: String, DomainModel, CaseIterable {
        case allowNotifications
        case geodataMissing
        case geodataUpdated
        case transactionAccepted
        case transactionExpired
        case transactionPending
        case transactionRejected

        init(from response: NotificationsSettingsModel.SettingsType) {
            switch response {
                case .geodataMissing:
                    self = .geodataMissing
                case .geodataUpdated:
                    self = .geodataUpdated
                case .transactionAccepted:
                    self = .transactionAccepted
                case .transactionExpired:
                    self = .transactionExpired
                case .transactionPending:
                    self = .transactionPending
                case .transactionRejected:
                    self = .transactionRejected
            }
        }

        var title: String {
            switch self {
                case .allowNotifications:
                    Localization.AllowNotifications.title
                case .geodataMissing:
                    Localization.GeodataMissing.title
                case .geodataUpdated:
                    Localization.GeodataUpdated.title
                case .transactionAccepted:
                    Localization.TransactionAccept.title
                case .transactionRejected:
                    Localization.TransactionReject.title
                case .transactionPending:
                    Localization.TransactionPending.title
                case .transactionExpired:
                    Localization.TransactionExp.title
            }
        }

        var id: Self { self }

        var subtitle: String? {
            switch self {
                case .allowNotifications:
                    Localization.AllowNotifications.subtitle
                default:
                    nil
            }
        }

        var toSettingType: NotificationsSettingsModel.SettingsType? {
            switch self {
                case .geodataMissing:
                    return .geodataMissing
                case .geodataUpdated:
                    return .geodataUpdated
                case .transactionAccepted:
                    return .transactionAccepted
                case .transactionExpired:
                    return .transactionExpired
                case .transactionPending:
                    return .transactionPending
                case .transactionRejected:
                    return .transactionRejected
                case .allowNotifications:
                    return nil
            }
        }
    }
}
