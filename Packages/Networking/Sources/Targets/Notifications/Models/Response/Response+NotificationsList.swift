//
//  Response+NotificationsList.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 24.06.2025.
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
import RestClient

extension ResponseModels {
    // MARK: - NotificationsList
    public struct NotificationsList: AnyPaginationDataResponse {
        public let data: [Notification]
        public let pagination: Pagination

        public init(data: [Notification], pagination: Pagination) {
            self.data = data
            self.pagination = pagination
        }
    }

    // MARK: - Notification
    public struct Notification: Decodable {
        public let id: String
        public let data: NotificationData
        public let createdAt: String
        public let type: NotificationType
        public let status: Status

        public init(id: String, data: NotificationData, createdAt: String, type: NotificationType, status: Status) {
            self.id = id
            self.data = data
            self.createdAt = createdAt
            self.type = type
            self.status = status
        }
    }
}

// MARK: - NotificationType
extension ResponseModels.Notification {
    public enum NotificationType: String, Decodable {
        case transactionPending = "transaction_pending"
        case transactionAccepted = "transaction_accepted"
        case transactionRejected = "transaction_rejected"
        case transactionExpired = "transaction_expired"
        case geodataMissing = "geodata_missing"
    }
}

// MARK: - Status
extension ResponseModels.Notification {
    public enum Status: String, Decodable {
        case pending
        case read
    }
}

// MARK: - NotificationData
extension ResponseModels.Notification {
    public struct NotificationData: Decodable {
        public let transaction: ResponseModels.Transaction

        public init(transaction: ResponseModels.Transaction) {
            self.transaction = transaction
        }
    }
}
