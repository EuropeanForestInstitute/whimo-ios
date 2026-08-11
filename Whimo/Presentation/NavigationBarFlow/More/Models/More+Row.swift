//
//  More+Row.swift
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

private typealias Module = MoreModule
private typealias Localization = AppLocale.More.Row
private typealias Assets = AppAssets.SettingsMore

extension Module {
    enum Row: DomainModel, CaseIterable {
        case appVersion
        case legalInformation
        case logOut
        case deleteAccount

        var id: Self { self }

        var title: String {
            switch self {
                case .appVersion:
                    Localization.appVersion
                case .legalInformation:
                    Localization.legalInformation
                case .logOut:
                    Localization.logOut
                case .deleteAccount:
                    Localization.deleteAccount
            }
        }

        var leadingAccessory: Image {
            switch self {
                case .appVersion:
                    Assets.settingsMoreAppVersion.imageSwiftUI
                case .legalInformation:
                    Assets.settingsMoreTerms.imageSwiftUI
                case .logOut:
                    Assets.settingsMoreLogout.imageSwiftUI
                case .deleteAccount:
                    Assets.settingsMoreDeleteAccount.imageSwiftUI
            }
        }

        var enableTrailingIndicator: Bool {
            switch self {
                case .legalInformation:
                    true
                default:
                    false
            }
        }
    }
}
