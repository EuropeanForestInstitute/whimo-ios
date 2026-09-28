//
//  TransactionDetailsViewModel+Presentation.swift
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
import Utility

extension TransactionDetailsModule.ViewModel {
    var rows: IdentifiedArrayOf<TransactionDetailsModule.Row> {
        do {
            let optionalStatus = transaction.value?.status
            let status = try optionalStatus.unwrap()

            switch status {
                case .automatic:
                    return .init(uniqueElements: TransactionDetailsModule.Row.automaticStatusCases)
                case .pending:
                    return .init(uniqueElements: TransactionDetailsModule.Row.pendingStatusCases)
                default:
                    return .init(uniqueElements: TransactionDetailsModule.Row.plainStatusCases)
            }
        } catch {
            return []
        }
    }
    var waitingCreatorResponse: Bool {
        transaction.value?.status == .pending
        && transaction.value?.createdById == userModel.id
    }
    var waitingRecipientResponse: Bool {
        transaction.value?.status == .pending
        && transaction.value?.createdById != userModel.id
        && (transaction.value?.seller?.id == userModel.id || transaction.value?.buyer?.id == userModel.id)
    }
    var isLoaded: Bool {
        transaction.isLoaded
        && pieChartData.isLoaded
        && supplierTransactions.isLoaded
    }
}
