//
//  UserModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 23.05.2025.
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
import DatabaseKit

struct UserModel: Codable, DomainModel, AutoStringConvertible {
    static let empty: Self = .init(id: "N/A", username: "N/A", gadgets: [])

    public static var kOfflineModeRecipientName: String { DatabaseKit.User.kOfflineModeRecipientName }

    let id: String
    let username: String
    let gadgets: [GadgetModel]
}

// MARK: - GadgetModel
extension UserModel {
    struct GadgetModel: Codable, DomainModel, AutoStringConvertible {
        let identifier: String
        let type: GadgetType
        let isVerified: Bool

        var id: String { identifier }
        var isEmpty: Bool { identifier.isEmpty && !isVerified }

        static func unverified(identifier: String, type: GadgetType) -> Self {
            Self(identifier: identifier, type: type, isVerified: false)
        }
    }
}

// MARK: - GadgetType
extension UserModel.GadgetModel {
    enum GadgetType: String, Codable, DomainModel {
        case email = "email"
        case phone = "phone"

        var id: Self { self }
    }
}
