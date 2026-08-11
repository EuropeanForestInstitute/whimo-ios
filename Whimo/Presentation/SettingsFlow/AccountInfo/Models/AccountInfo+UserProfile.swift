//
//  AccountInfo+UserProfile.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.08.2025.
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

private typealias Module = AccountInfoModule

// MARK: - UserProfile
extension Module {
    struct UserProfile: Identifiable, Hashable {
        static let empty: Self = .init(id: "N/A", username: "N/A")

        let id: String
        let username: String
        let email: UserModel.GadgetModel?
        let phone: UserModel.GadgetModel?

        init(
            id: String,
            username: String,
            email: UserModel.GadgetModel? = nil,
            phone: UserModel.GadgetModel? = nil
        ) {
            self.id = id
            self.username = username
            self.email = email
            self.phone = phone
        }

        init(from model: UserModel) {
            let email: UserModel.GadgetModel? = model.gadgets.first { $0.type == .email }
            let phone: UserModel.GadgetModel? = model.gadgets.first { $0.type == .phone }

            self.init(
                id: model.id,
                username: model.username,
                email: email,
                phone: phone
            )
        }
    }
}
