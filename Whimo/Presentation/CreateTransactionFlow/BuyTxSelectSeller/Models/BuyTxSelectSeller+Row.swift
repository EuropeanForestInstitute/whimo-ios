//
//  BuyTxSelectSeller+Row.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 10.06.2025.
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

private typealias Module = BuyTxSelectSellerModule
private typealias Localization = AppLocale.BuyTxSelectSeller.Row
private typealias Assets = AppAssets.BuyTxSelectSeller

// MARK: - Row
extension Module {
    enum Row: DomainModel, CaseIterable {
        case farmer
        case cooperative

        var id: Self { self }

        var icon: Image {
            switch self {
                case .farmer:
                    Assets.buyTxSelectSellerFarmerIcon.imageSwiftUI
                case .cooperative:
                    Assets.buyTxSelectSellerFarmerIcon.imageSwiftUI
            }
        }

        var title: String {
            switch self {
                case .farmer:
                    Localization.Farmer.title
                case .cooperative:
                    Localization.Cooperate.title
            }
        }

        var subtitle: String {
            switch self {
                case .farmer:
                    Localization.Farmer.subtitle
                case .cooperative:
                    Localization.Cooperate.subtitle
            }
        }
    }
}
