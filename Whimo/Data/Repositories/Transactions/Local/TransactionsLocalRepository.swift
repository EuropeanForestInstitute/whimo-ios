//
//  TransactionsLocalRepository.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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

protocol TransactionsLocalRepository: AnyObject {
    typealias TransactionsData = (list: IdentifiedArrayOf<TransactionModel>, pagination: RestClient.Pagination)
    typealias TransactionsPagination = RequestModels.TransactionsList

    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData
    func fetchTransaction(by id: String) async throws -> TransactionModel
    func fetchOnDiskTransactions() async throws -> IdentifiedArrayOf<TransactionModel>

    func save(_ model: TransactionModel) async throws
    func saveProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool
    ) async throws -> TransactionModel
    func saveDownstreamTransaction(
        commodityId: String,
        volume: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        action: TransactionModel.Action,
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
    ) async throws -> TransactionModel

    func delete(_ transaction: TransactionModel) async throws
    func deleteTxRecepient(_ user: UserModel?) async throws
}
