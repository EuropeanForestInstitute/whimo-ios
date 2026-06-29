//
//  Request+CreateDownstreamTransaction.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 11.06.2025.
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
import Networking
import RestClient

// MARK: - Downstream
extension RequestModels.CreateTransaction {
    public struct Downstream: Encodable {
        public let transactionData: TransactionData
        public let uploadFile: UploadFile?

        public init(transactionData: TransactionData, uploadFile: UploadFile?) {
            self.transactionData = transactionData
            self.uploadFile = uploadFile
        }
    }
}

// MARK: - TransactionData
extension RequestModels.CreateTransaction.Downstream {
    public struct TransactionData: DataMultipartEncodable {
        public let commodityId: String
        public let volume: String
        public let location: RequestModels.CreateTransaction.LocationType?
        /// Used for: buy commodity > downstream tx
        public let farmLatitude: String?
        /// Used for: buy commodity > downstream tx
        public let farmLongitude: String?
        public let transactionLatitude: String?
        public let transactionLongitude: String?
        public let action: Action
        public let recipient: Recipient

        public init(
            commodityId: String,
            volume: String,
            location: RequestModels.CreateTransaction.LocationType?,
            farmLatitude: String?,
            farmLongitude: String?,
            transactionLatitude: String? = nil,
            transactionLongitude: String? = nil,
            action: Action,
            recipient: Recipient
        ) {
            self.commodityId = commodityId
            self.volume = volume
            self.location = location
            self.farmLatitude = farmLatitude
            self.farmLongitude = farmLongitude
            self.transactionLatitude = transactionLatitude
            self.transactionLongitude = transactionLongitude
            self.action = action
            self.recipient = recipient
        }
    }
}

// MARK: - Action
extension RequestModels.CreateTransaction.Downstream {
    public enum Action: String, Encodable {
        case buy = "buying"
        case sell = "selling"

        public var id: Self { self }
    }
}

// MARK: - Recipient
extension RequestModels.CreateTransaction.Downstream.TransactionData {
    public struct Recipient: Encodable {
        public let name: String?
        public let email: String?
        public let phone: String?

        public init(
            name: String? = nil,
            email: String? = nil,
            phone: String? = nil
        ) {
            self.name = name
            self.email = email
            self.phone = phone
        }

        public static func name(_ value: String) -> Self {
            .init(name: value)
        }

        public static func email(_ value: String) -> Self {
            .init(email: value)
        }

        public static func phone(_ value: String) -> Self {
            .init(phone: value)
        }
    }
}
