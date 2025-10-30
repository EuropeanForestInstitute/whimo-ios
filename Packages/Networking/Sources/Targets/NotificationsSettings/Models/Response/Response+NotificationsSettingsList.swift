//
//  Response+NotificationsSettingsList.swift
//  Whimo
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
import RestClient

extension ResponseModels {
    // MARK: - NotificationsSettingsList
    public struct NotificationsSettingsList: AnyDataResponse {
        public let data: [NotificationsSettings]

        public init(data: [NotificationsSettings]) {
            self.data = data
        }
    }

    // MARK: - NotificationsSettings
    public struct NotificationsSettings: Decodable {
        public let type: SettingsType
        public let isEnabled: Bool

        public init(type: SettingsType, isEnabled: Bool) {
            self.type = type
            self.isEnabled = isEnabled
        }
    }
}

// MARK: - SettingsType
extension ResponseModels.NotificationsSettings {
    public enum SettingsType: String, Decodable {
        case geodataMissing = "geodata_missing"
        case geodataUpdated = "geodata_updated"
        case transactionAccepted = "transaction_accepted"
        case transactionExpired = "transaction_expired"
        case transactionPending = "transaction_pending"
        case transactionRejected = "transaction_rejected"
    }
}
