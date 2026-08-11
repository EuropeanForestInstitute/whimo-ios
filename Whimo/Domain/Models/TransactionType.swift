//
//  TransactionType.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.06.2025.
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
import typealias Utility.DomainModel
import protocol Utility.AutoStringConvertible

enum TransactionType: DomainModel, AutoStringConvertible {
    case producer(seller: Seller)
    case downstream(action: TransactionModel.Action, recipient: Recipient)

    var id: Self { self }

    var isProducer: Bool {
        switch self {
            case .producer:
                true
            case .downstream:
                false
        }
    }

    var isDownstream: Bool {
        switch self {
            case .producer:
                false
            case .downstream:
                true
        }
    }
}

// MARK: - Seller
extension TransactionType {
    enum Seller: DomainModel {
        case farmer(isCurrentlyOnFarm: Bool)
        case cooperative(recipient: TransactionType.Recipient? = nil)

        var id: Self { self }

        var isFarmer: Bool {
            switch self {
                case .farmer:
                    true
                case .cooperative:
                    false
            }
        }

        var isCooperative: Bool {
            switch self {
                case .farmer:
                    false
                case .cooperative:
                    true
            }
        }
    }
}

// MARK: - Recipient
extension TransactionType {
    struct Recipient: DomainModel {
        static let empty: Self = .init(recipientID: "", email: "", phone: "")

        var recipientID: String
        var email: String
        var phone: String

        var id: Self { self }

        var recipientContact: String? {
            if !recipientID.isEmpty {
                return recipientID
            } else if !email.isEmpty {
                return email
            } else if !phone.isEmpty {
                return phone
            }

            return nil
        }
    }
}
