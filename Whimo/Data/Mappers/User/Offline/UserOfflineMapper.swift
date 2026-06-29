//
//  UserOfflineMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.07.2025.
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
import DatabaseKit
import RestClient

struct UserOfflineMapper: UserOfflineMapperProtocol {
    // MARK: - DTO -> Database
    func toDatabase(
        from dto: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
    ) -> DatabaseKit.User {
        var gadgets: [DatabaseKit.User.Gadget] = []
        if let email = dto.email {
            let gadget: DatabaseKit.User.Gadget = .init(
                id: UUID().uuidString,
                identifier: email,
                type: .email,
                isVerified: true
            )
            gadgets.append(gadget)
        }
        if let phone = dto.phone {
            let gadget: DatabaseKit.User.Gadget = .init(
                id: UUID().uuidString,
                identifier: phone,
                type: .phone,
                isVerified: true
            )
            gadgets.append(gadget)
        }

        return .init(
            id: UUID().uuidString,
            username: dto.name ?? DatabaseKit.User.kOfflineModeRecipientName,
            gadgets: gadgets
        )
    }
}
