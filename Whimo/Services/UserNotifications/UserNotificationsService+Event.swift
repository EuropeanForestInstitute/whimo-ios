//
//  UserNotificationsService+Event.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 14.07.2025.
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

// MARK: - Event
extension UserNotificationsService {
    enum Event: DictionaryDecodable, AutoStringConvertible {
        private enum Constants {
            static let transactionUpdateKey = "transactionUpdate"
        }

        // MARK: - Cases

        // swiftlint:disable all
        /// Example:
        ///
        ///{
        ///   "aps": {
        ///      "alert": {
        ///         "body": "{\"id\":\"ee4b9dbd-ee78-4cc0-b72b-4b63300392e5\",\"created_at\":\"2025-06-18T15:02:35.354998Z\",\"data\":{\"transaction_id\":\"471f4efa-e93c-4bae-a38e-4e7d4a4f5d14\"},\"type\":\"transaction_pending\",\"status\":\"pending\",\"received_by\":{\"id\":\"8be36341-613c-4461-b85e-4734521696f\",\"username\":\"mature-elegant-leech-aa6d0c\",\"gadgets\":[{\"id\":\"d2a63cb0-81ba-4722-8577-b785f8a610c4\",\"type\":\"email\",\"identifier\":\"slawa.test.user045@gmail.com\",\"is_verified\":true}]},\"created_by\":{\"id\":\"8be36341-613c-4461-b85e-4734521696f5\",\"username\":\"mature-elegant-leech-aa6d0c\",\"gadgets\":[{\"id\":\"d2a63cb0-81ba-4722-8577-b785f8a610c4\",\"type\":\"email\",\"identifier\":\"slawa.test.user045@gmail.com\",\"is_verified\":true}]}}"
        ///      },
        ///      "mutable-content": 1
        ///   }
        ///}
        ///
        // swiftlint:enable all
        case transactionUpdate(TransactionUpdate)
        case unknown(value: String?)

        // MARK: - CodingKeys
        enum CodingKeys: CodingKey {
            case type
        }

        // MARK: - Inits
        init(from decoder: any Decoder) throws {
            let singleValueContainer = try decoder.singleValueContainer()
            let type = Constants.transactionUpdateKey

            switch type {
                case Constants.transactionUpdateKey:
                    let model = try singleValueContainer.decode(TransactionUpdate.self)
                    self = .transactionUpdate(model)
                default:
                    self = .unknown(value: type)
            }
        }
    }
}

// MARK: - TransactionUpdate
extension UserNotificationsService.Event {
    struct TransactionUpdate: Decodable, AutoStringConvertible {
        struct Aps: Decodable, AutoStringConvertible {
            struct Alert: Decodable, AutoStringConvertible {
                let body: String

                func toModel() throws -> Notifications.Push {
                    let data: Data = body.data(using: .utf8) ?? .init()
                    let decoder: JSONDecoder = .init()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let model = try decoder.decode(Notifications.Push.self, from: data)
                    return model
                }
            }

            let alert: Alert
        }

        let aps: Aps
    }
}
