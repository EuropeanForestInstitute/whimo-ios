//
//  CreateTransactionForm+Row.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import Resources
import struct CommonUI.FontBuilder
import typealias Utility.DomainModel
import struct Utility.AttributedStringBuilder

private typealias Module = CreateTransactionFormModule
private typealias Localization = AppLocale.CreateTransactionForm.Row
private typealias Assets = AppAssets.CreateTransactionForm

// MARK: - Row
extension Module {
    enum Row: DomainModel {
        case geodata
        case commodity
        case volume
        case inviteSupplier
        case supplier
        case buyer

        var id: Self { self }

        var title: AttributedString {
            switch self {
                case .geodata:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.Geodata.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )
                    )
                case .commodity:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.ComodityType.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        ),
                        (
                            Localization.ComodityType.titleSuffix,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Expanded.expandedError.color
                            ])
                        ),
                    )
                case .volume:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.Volumes.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        ),
                        (
                            Localization.Volumes.titleSuffix,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Expanded.expandedError.color
                            ])
                        )
                    )
                case .inviteSupplier:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.Supplier.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )
                    )
                case .supplier:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.Supplier.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )
                    )
                case .buyer:
                    AttributedStringBuilder.build(from:
                        (
                            Localization.Buyer.title,
                            .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )
                    )
            }
        }

        var placeholder: String {
            switch self {
                case .geodata:
                    Localization.Placeholder.geodata
                case .inviteSupplier:
                    Localization.Placeholder.inviteSupplier
                default:
                    Localization.Placeholder.default
            }
        }

        var leadingAccessory: Image {
            switch self {
                case .geodata:
                    Assets.createTransactionFormMapPin.imageSwiftUI
                case .commodity:
                    Assets.createTransactionFormCommodityIcon.imageSwiftUI
                case .volume:
                    Assets.createTransactionFormVolumeIcon.imageSwiftUI
                case .inviteSupplier, .supplier, .buyer:
                    Assets.createTransactionFormUserIcon.imageSwiftUI
            }
        }
    }
}
