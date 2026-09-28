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
    private let businessDataContext: BusinessDataContext
    private let localRepo: TransactionsLocalRepository
    private let remoteRepo: TransactionsRemoteRepository

    // MARK: - Init
    init(localRepo: TransactionsLocalRepository, remoteRepo: TransactionsRemoteRepository,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.localRepo = localRepo
        self.remoteRepo = remoteRepo
    }

    // MARK: - TransactionsCachingRepository
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        try await businessDataContext.withCurrentGeneration {
            do {
                let response = try await remoteRepo.fetchTransactions(with: pagination)
                for transaction in response.list {
                    try await localRepo.save(transaction)
                }
                return (response.list, response.pagination, false)
            } catch RestClient.RestError.connectionLost {
                let response = try await localRepo.fetchTransactions(with: pagination)
                return (response.list, response.pagination, true)
            }
        }
    }

    func fetchSupplierTransactions(with pagination: TransactionsPagination) async throws -> SupplierTransactionsData {
        try await businessDataContext.withCurrentGeneration {
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
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
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
    }

    func createProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool,
        season: HarvestSeason
    ) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            do {
                let transaction = try await remoteRepo.createProducerTransaction(
                    commodityId: commodityId,
                    location: location,
                    uploadFile: uploadFile,
                    farmCoordinates: farmCoordinates,
                    transactionCoordinates: transactionCoordinates,
                    volume: volume,
                    inviteRecipient: inviteRecipient,
                    isBuyingFromFarmer: isBuyingFromFarmer,
                    season: season
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
                    isBuyingFromFarmer: isBuyingFromFarmer,
                    season: season
                )
                return localTransaction
            } catch {
                throw error
            }
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
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient,
        season: HarvestSeason?
    ) async throws -> TransactionModel {
        try await businessDataContext.withCurrentGeneration {
            do {
                let transaction = try await remoteRepo.createDownstreamTransaction(
                    commodityId: commodityId,
                    location: location,
                    transactionCoordinates: transactionCoordinates,
                    uploadFile: uploadFile,
                    farmCoordinates: farmCoordinates,
                    volume: volume,
                    action: action,
                    recipient: recipient,
                    season: season
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
                    recipient: recipient,
                    season: season
                )
                return localTransaction
            } catch {
                throw error
            }
        }
    }
}
