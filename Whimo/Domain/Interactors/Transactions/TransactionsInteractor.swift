//
//  TransactionsInteractor.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.05.2025.
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
import struct CoreLocation.CLLocationCoordinate2D
import typealias Utility.IdentifiedArrayOf
import RestClient

protocol TransactionsInteractor: AnyObject {
    typealias TransactionsPagination = RequestModels.TransactionsList

    /// Fetches transactions from network with cache fallback
    func fetchTransactions(
        searchData: TransactionsPagination.SearchData,
        refresh: Bool
    ) async throws

    /// Fetches transactions from local cache only (offline mode)
    func fetchTransactionsFromCache() async throws

    func fetchSuppliersTransactions(
        commodityGroupId: String,
        buyerId: String,
        oldPagination: TransactionsPagination?,
        refresh: Bool
    ) async throws -> (list: IdentifiedArrayOf<SupplierTransactionModel>, pagination: TransactionsPagination)
    @discardableResult
    func fetchTransaction(by id: String) async throws -> TransactionModel

    func createProducerTransaction(
        farmLocation: FarmLocation?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        isBuyingFromFarmer: Bool,
        transactionCoordinates: CLLocationCoordinate2D?,
        inviteRecipient: TransactionType.Recipient?
    ) async throws
    func createDownstreamTransaction(
        farmLocation: FarmLocation?,
        transactionCoordinates: CLLocationCoordinate2D?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        action: TransactionModel.Action,
        recipient: TransactionType.Recipient
    ) async throws

    func updateTransaction(transactionId: String, status: RequestModels.UpdateTransactionStatus.Status) async throws -> TransactionModel
    func updateTransactionGeodata(
        transactionId: String,
        file: FileObject
    ) async throws
}
