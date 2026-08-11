//
//  TransactionsCachingRepositoryImpl.swift
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
import RestClient

final class TransactionsCachingRepositoryImpl: TransactionsCachingRepository {
    // MARK: - Dependencies
    private let localRepo: TransactionsLocalRepository
    private let remoteRepo: TransactionsRemoteRepository

    // MARK: - Init
    init(localRepo: TransactionsLocalRepository, remoteRepo: TransactionsRemoteRepository) {
        self.localRepo = localRepo
        self.remoteRepo = remoteRepo
    }

    // MARK: - TransactionsCachingRepository
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        var remotePagination: RestClient.Pagination?
        do {
            let transactions = try await remoteRepo.fetchTransactions(with: pagination)
            remotePagination = transactions.pagination

            for transaction in transactions.list {
                try await localRepo.save(transaction)
            }
        } catch RestClient.RestError.connectionLost {
        } catch {
            throw error
        }

        let localTransactions = try await localRepo.fetchTransactions(with: pagination)

        var nextPage: Int?
        var previousPage: Int?
        if let value = localTransactions.pagination.nextPage, remotePagination?.nextPage == nil {
            nextPage = value
        }
        if let value = remotePagination?.nextPage, localTransactions.pagination.nextPage == nil {
            nextPage = value
        }
        if let localNextPage = localTransactions.pagination.nextPage,
           let remoteNextPage = remotePagination?.nextPage {
            if localNextPage < remoteNextPage {
                nextPage = remoteNextPage
            } else {
                nextPage = localNextPage
            }
        }

        if let nextPage {
            previousPage = max(nextPage - 1, 1)
        }

        let pagination: RestClient.Pagination = .init(
            pageSize: pagination.pageData.pageSize,
            nextPage: nextPage,
            previousPage: previousPage,
            count: localTransactions.pagination.count,
            totalPages: localTransactions.pagination.totalPages,
            page: localTransactions.pagination.page
        )
        return (
            list: localTransactions.list,
            pagination: pagination
        )
    }

    func fetchSupplierTransactions(with pagination: TransactionsPagination) async throws -> SupplierTransactionsData {
        do {
            let transactions = try await remoteRepo.fetchSupplierTransactions(with: pagination)

            return transactions
        } catch RestClient.RestError.connectionLost {
            return (
                list: [],
                pagination: .empty
            )
        } catch {
            throw error
        }
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        do {
            let transaction = try await remoteRepo.fetchTransaction(by: id)

            try await localRepo.save(transaction)

            return transaction
        } catch RestClient.RestError.connectionLost {
            let localTransaction = try await localRepo.fetchTransaction(by: id)
            return localTransaction
        } catch {
            throw error
        }
    }

    func createProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool
    ) async throws -> TransactionModel {
        do {
            let transaction = try await remoteRepo.createProducerTransaction(
                commodityId: commodityId,
                location: location,
                uploadFile: uploadFile,
                farmCoordinates: farmCoordinates,
                transactionCoordinates: transactionCoordinates,
                volume: volume,
                inviteRecipient: inviteRecipient,
                isBuyingFromFarmer: isBuyingFromFarmer
            )
            try await localRepo.save(transaction)
            return transaction
        } catch RestClient.RestError.connectionLost {
            let localTransaction = try await localRepo.saveProducerTransaction(
                commodityId: commodityId,
                location: location,
                uploadFile: uploadFile,
                farmCoordinates: farmCoordinates,
                transactionCoordinates: transactionCoordinates,
                volume: volume,
                inviteRecipient: inviteRecipient,
                isBuyingFromFarmer: isBuyingFromFarmer
            )
            return localTransaction
        } catch {
            throw error
        }
    }

    func createDownstreamTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        action: TransactionModel.Action,
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient
    ) async throws -> TransactionModel {
        do {
            let transaction = try await remoteRepo.createDownstreamTransaction(
                commodityId: commodityId,
                location: location,
                transactionCoordinates: transactionCoordinates,
                uploadFile: uploadFile,
                farmCoordinates: farmCoordinates,
                volume: volume,
                action: action,
                recipient: recipient
            )
            try await localRepo.save(transaction)
            return transaction
        } catch RestClient.RestError.connectionLost {
            let localTransaction = try await localRepo.saveDownstreamTransaction(
                commodityId: commodityId,
                volume: volume,
                location: location,
                uploadFile: uploadFile,
                farmCoordinates: farmCoordinates,
                transactionCoordinates: transactionCoordinates,
                action: action,
                recipient: recipient
            )
            return localTransaction
        } catch {
            throw error
        }
    }
}
