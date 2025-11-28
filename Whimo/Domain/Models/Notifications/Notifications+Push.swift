//
//  Notifications+Push.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 15.07.2025.
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
import Resources

private typealias Localization = AppLocale.NotificationsList.Row

extension Notifications {
    struct Push: Codable, AutoStringConvertible {
        struct Data: Codable, AutoStringConvertible {
            struct Transaction: Codable, AutoStringConvertible {
                let id: String
            }

            let transaction: Transaction
        }

        let id: String
        let data: Notifications.Push.Data
        let createdAt: String
        let type: PushNotificationType
        let status: PushStatus
    }
}

// MARK: - NotificationType
extension Notifications.Push {
    enum PushNotificationType: String, Codable {
        case transactionPending = "transaction_pending"
        case transactionAccepted = "transaction_accepted"
        case transactionRejected = "transaction_rejected"
        case transactionExpired = "transaction_expired"
        case geodataMissing = "geodata_missing"

        var title: String {
            switch self {
                case .transactionPending:
                    Localization.Pending.title
                case .transactionAccepted:
                    Localization.Accepted.title
                case .transactionRejected:
                    Localization.Rejected.title
                case .transactionExpired:
                    Localization.Expired.title
                case .geodataMissing:
                    Localization.GeodataMissing.title
            }
        }
    }
}

// MARK: - Status
extension Notifications.Push {
    enum PushStatus: String, Codable {
        case pending
        case read
    }
}
