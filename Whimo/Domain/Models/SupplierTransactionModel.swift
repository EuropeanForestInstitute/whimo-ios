//
//  SupplierTransactionModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.06.2025.
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

// MARK: - SupplierTransactionModel
struct SupplierTransactionModel: DomainModel, AutoStringConvertible {
    let id: String
    let createdAt: String
    let type: TransactionModel.TransactionType
    let status: TransactionModel.Status
    let traceability: TransactionModel.Traceability?
    let location: TransactionModel.LocationType?
    let latitude: Double?
    let longitude: Double?
    let volume: Double
    let isBuyingFromFarmer: Bool
    let commodity: CommodityGroupModel.Commodity
    let seller: UserModel?
    let buyer: UserModel?
    let createdById: String?
}
