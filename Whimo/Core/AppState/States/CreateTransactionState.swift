//
//  CreateTransactionState.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 23.05.2025.
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

struct CreateTransactionState: AnyState {
    // MARK: - Static
    static let initialState: Self = .init()
    static let preview: Self = .init()
    static let test: Self = .init()

    // MARK: - Activity
    enum Activity { }

    // MARK: - Properties
    var commodityType: CommodityGroupModel.Commodity = .initialState
    var volumeAmount: String = ""
    var transactionType: TransactionType?
    var farmLocation: FarmLocation?
    var balances: IdentifiedArrayOf<CommodityBalanceModel> = []

    mutating func clear() {
        commodityType = .initialState
        volumeAmount = ""
        transactionType = nil
        farmLocation = nil
        balances = []
    }
}
