//
//  TransactionDetails+Row.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.05.2025.
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

private typealias Module = TransactionDetailsModule
private typealias Localization = AppLocale.TransactionDetails

extension Module {
    enum Row: DomainModel {
        case commodityType
        case farmGeodata
        case traceabilityStatus
        case buyerID
        case supplierInformation
        case transactionStatus
        case transactionDate
        case expireDate

        var id: Self { self }

        var title: String {
            switch self {
                case .commodityType:
                    Localization.Row.CommodityType.title
                case .farmGeodata:
                    Localization.Row.FarmGeodata.title
                case .traceabilityStatus:
                    Localization.Row.TraceabilityStatus.title
                case .buyerID:
                    Localization.Row.BuyerID.title
                case .supplierInformation:
                    Localization.Row.SupplierInformation.title
                case .transactionStatus:
                    Localization.Row.TransactionStatus.title
                case .transactionDate:
                    Localization.Row.TransactionDate.title
                case .expireDate:
                    Localization.Row.ExpireDate.title
            }
        }

        var enableTrailingIndicator: Bool {
            switch self {
                case .commodityType, .buyerID, .transactionDate, .expireDate:
                    false
                default:
                    true
            }
        }

        static var plainStatusCases: [TransactionDetailsModule.Row] {
            [
                .commodityType,
                .traceabilityStatus,
                .buyerID,
                .supplierInformation,
                .transactionStatus,
                .transactionDate
            ]
        }

        static var automaticStatusCases: [TransactionDetailsModule.Row] {
            [
                .commodityType,
                .farmGeodata,
                .transactionStatus,
                .transactionDate
            ]
        }

        static var pendingStatusCases: [TransactionDetailsModule.Row] {
            [
                .commodityType,
                .traceabilityStatus,
                .buyerID,
                .supplierInformation,
                .transactionStatus,
                .transactionDate,
                .expireDate
            ]
        }
    }
}
