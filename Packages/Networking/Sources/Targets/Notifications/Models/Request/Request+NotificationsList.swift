//
//  Request+NotificationsList.swift
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

// MARK: - NotificationsList
extension RequestModels {
    public struct NotificationsList: Encodable, Equatable {
        public let notificationTypes: [NotificationType]
        public let status: Status?
        public let pageData: PaginationRequest

        /// Cached value. Indicates is next page reachable on BE.
        /// Only for internal usage. Do not use this property to make requests.
        public var nextPage: Int?
        public var hasNextPage: Bool { nextPage != nil }

        public static func initial(notificationTypes: [NotificationType] = []) -> Self {
            .init(
                notificationTypes: notificationTypes,
                status: nil,
                pageData: .initial
            )
        }

        public static func initialPending(notificationTypes: [NotificationType] = []) -> Self {
            .init(
                notificationTypes: notificationTypes,
                status: .pending,
                pageData: .initial
            )
        }

        public init(
            notificationTypes: [NotificationType] = [],
            status: Status? = nil,
            pageData: PaginationRequest
        ) {
            self.notificationTypes = notificationTypes
            self.status = status
            self.pageData = pageData
        }

        public enum CodingKeys: CodingKey {
            case types
            case status
            case page
            case pageSize
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeIfPresent(notificationTypes, forKey: .types)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encode(pageData.page, forKey: .page)
            try container.encode(pageData.pageSize, forKey: .pageSize)
        }
    }
}

// MARK: - NotificationsType
extension RequestModels.NotificationsList {
    public enum NotificationType: String, Encodable {
        case transactionPending = "transaction_pending"
        case transactionAccepted = "transaction_accepted"
        case transactionRejected = "transaction_rejected"
        case transactionExpired = "transaction_expired"
        case geodataMissing = "geodata_missing"

        public static var requireActions: [Self] { [.transactionPending, .geodataMissing] }
    }
}

// MARK: - Status
extension RequestModels.NotificationsList {
    public enum Status: String, Encodable {
        case pending
        case read
    }
}
