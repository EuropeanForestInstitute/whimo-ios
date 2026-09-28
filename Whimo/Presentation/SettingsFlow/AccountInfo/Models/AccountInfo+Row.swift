//
//  AccountInfo+Row.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

import SwiftUI
import typealias Utility.DomainModel
import Resources

private typealias Module = AccountInfoModule
private typealias Localization = AppLocale.AccountInfo.Row
private typealias Assets = AppAssets.AccountInfo

extension Module {
    enum Row: DomainModel {
        case userID(username: String)
        case email(gadget: UserModel.GadgetModel?)
        case phone(gadget: UserModel.GadgetModel?)

        var id: Self { self }

        var title: String {
            switch self {
                case .userID:
                    Localization.UserID.title
                case .email:
                    Localization.Email.title
                case .phone:
                    Localization.Phone.title
            }
        }

        var emptyDetailsTitle: String {
            switch self {
                case .userID:
                    ""
                case .email:
                    Localization.Email.noDetailsTitle
                case .phone:
                    Localization.Phone.noDetailsTitle
            }
        }

        var leadingAccessory: Image {
            switch self {
                case .userID:
                    Assets.accountInfoUserIcon.imageSwiftUI
                case .email:
                    Assets.accountInfoEmailIcon.imageSwiftUI
                case .phone:
                    Assets.accountInfoPhoneIcon.imageSwiftUI
            }
        }

        var details: String? {
            switch self {
                case .userID(username: let username):
                    username
                case .email(let gadget):
                    gadget?.identifier
                case .phone(let gadget):
                    gadget?.identifier
            }
        }

        var emptyDetailsMessage: String {
            switch self {
                case .userID:
                    ""
                case .email:
                    Localization.Email.noDetailsMessage
                case .phone:
                    Localization.Phone.noDetailsMessage
            }
        }

        var isVerified: Bool {
            switch self {
                case .userID:
                    true
                case .email(let gadget),
                     .phone(let gadget):
                    gadget?.isVerified ?? true
            }
        }

        var noVerificationMessage: String {
            switch self {
                case .userID:
                    ""
                case .email:
                    Localization.Email.noVerification
                case .phone:
                    Localization.Phone.noVerification
            }
        }
    }
}
