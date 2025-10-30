//
//  SuppliersHistory+SupplierInfo.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.06.2025.
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
import protocol Utility.AutoStringConvertible

private typealias Module = SuppliersHistoryModule

// MARK: - SupplierInfo
extension Module {
    struct SupplierInfo: AutoStringConvertible {
        // MARK: - Properties
        let transactionId: String
        let commodityGroupId: String
        let supplier: UserModel
        let supplierType: SupplierType
        let traceability: TransactionModel.Traceability?

        // MARK: - Inits
        init?(from model: TransactionModel) {
            guard let seller = model.seller else { return nil }

            self.transactionId = model.id
            self.commodityGroupId = model.commodity.group.id
            self.supplier = seller
            self.supplierType = .mySupplier
            self.traceability = model.traceability
        }

        init?(from model: SupplierTransactionModel) {
            guard let seller = model.seller else { return nil }

            self.transactionId = model.id
            self.commodityGroupId = model.commodity.group.id
            self.supplier = seller
            self.supplierType = .other
            self.traceability = model.traceability
        }
    }
}

// MARK: - SupplierType
extension Module.SupplierInfo {
    enum SupplierType {
        case mySupplier
        case other
    }
}
