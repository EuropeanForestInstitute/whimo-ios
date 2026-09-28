//
//  OfflineTransactionsSyncServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.07.2025.
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
import RestClient
import Targets
import Utility

// MARK: - OfflineTransactionsSyncServiceImpl
actor OfflineTransactionsSyncInteractorImpl: OfflineTransactionsSyncInteractor {
    // MARK: - PendingTransaction
    enum PendingTransaction: AutoStringConvertible {
        case producer(RequestModels.CreateTransaction.Producer)
        case downstream(RequestModels.CreateTransaction.Downstream)
    }

    typealias PendingTuple = (domainModel: TransactionModel, requestModel: PendingTransaction)

    private var syncingGeneration: BusinessDataContext.Generation?
    // Retain a known result even if journaling fails; retry storage before any further POST.
    private var confirmedUploads: [String: TransactionModel] = [:]

    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let appState: any AppState
    private let transactionsLocalRepository: any TransactionsLocalRepository
    private let transactionsOfflineMapper: any TransactionsOfflineMapperProtocol

    private let transactionsTarget: any TransactionsTarget
    private let transactionsMapper: any TransactionsMapperProtocol

    // MARK: - Init
    init(
        appState: any AppState,
        transactionsLocalRepository: any TransactionsLocalRepository,
        transactionsOfflineMapper: any TransactionsOfflineMapperProtocol,
        transactionsTarget: any TransactionsTarget,
        transactionsMapper: any TransactionsMapperProtocol,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.appState = appState
        self.transactionsLocalRepository = transactionsLocalRepository
        self.transactionsOfflineMapper = transactionsOfflineMapper
        self.transactionsTarget = transactionsTarget
        self.transactionsMapper = transactionsMapper
    }

    func discardPendingResults() {
        confirmedUploads.removeAll()
        syncingGeneration = nil
    }

    // MARK: - OfflineTransactionsSyncInteractor
    func syncTransactions() async throws {
        try await businessDataContext.withProtectedWork {
            let generation = try businessDataContext.capture()
            guard syncingGeneration !== generation else { return }

            syncingGeneration = generation
            defer { if syncingGeneration === generation { syncingGeneration = nil } }
            let pendingTuples = try await fetchTransactions()
            for tuple in pendingTuples {
                do {
                    try await handlePendingTransaction(tuple)
                } catch {
                    try await MainActor.run {
                        try businessDataContext.capture().check()
                        appState.transactions.dispatch { state in
                            state.updateList(with: tuple.domainModel)
                            state.updatingList.remove(id: tuple.domainModel.id)
                        }
                    }
                    throw error
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension OfflineTransactionsSyncInteractorImpl {
    func fetchTransactions() async throws -> [PendingTuple] {
        let onDiskItems = try await transactionsLocalRepository.fetchOnDiskTransactions()
        return onDiskItems.compactMap { transaction in
            // Legacy seasonless test records remain untouched; new records require their captured ID.
            guard let seasonId = transaction.harvestSeasonId, !seasonId.isEmpty else { return nil }

            let request: PendingTransaction
            switch transaction.type {
                case .producer:
                    request = .producer(transactionsOfflineMapper.toDTO(from: transaction))
                case .downstream:
                    request = .downstream(transactionsOfflineMapper.toDTO(from: transaction))
                case .conversion:
                    return nil
            }
            return (transaction, request)
        }
    }

    func confirmedTransaction(for tuple: PendingTuple) async throws -> TransactionModel {
        let queued = tuple.domainModel
        if let transaction = confirmedUploads[queued.id] {
            try transactionsLocalRepository.saveConfirmedUploadID(transaction.id, for: queued)
            return transaction
        }
        if let remoteID = try transactionsLocalRepository.confirmedUploadID(for: queued) {
            // A read failure keeps the receipt and queue intact; it must never become another create.
            let response = try await transactionsTarget.getTransaction(.init(transactionId: remoteID))
            try businessDataContext.capture().check()
            guard response.data.id == remoteID else { throw CocoaError(.coderInvalidValue) }

            return transactionsMapper.toDomain(from: response.data)
        }
        let response: ResponseModels.TransactionInfo
        switch tuple.requestModel {
            case .producer(let request):
                response = try await transactionsTarget.createProducerTransaction(request)
            case .downstream(let request):
                response = try await transactionsTarget.createDownstreamTransaction(request)
        }
        try businessDataContext.capture().check()
        let transaction = transactionsMapper.toDomain(from: response.data)
        confirmedUploads[queued.id] = transaction
        try transactionsLocalRepository.saveConfirmedUploadID(transaction.id, for: queued)
        return transaction
    }

    func handlePendingTransaction(_ pendingTuple: PendingTuple) async throws {
        try await MainActor.run {
            try businessDataContext.capture().check()
            appState.transactions.dispatch { state in
                var transactions: IdentifiedArrayOf<TransactionModel> = state.list.value ?? []
                guard var tx = transactions[id: pendingTuple.domainModel.id] else { return }

                tx.persistingData = .uploading(farmLocationFile: tx.persistingData.farmLocationFile)
                transactions[id: pendingTuple.domainModel.id] = tx
                switch state.list {
                    case .requested:
                        state.list = .requested(lastValue: transactions)
                    case .isLoading:
                        state.list = .isLoading(lastValue: transactions)
                    case .loaded:
                        state.list = .loaded(value: transactions)
                    default:
                        break
                }
                state.updatingList.append(tx)
            }
        }

        let transaction = try await confirmedTransaction(for: pendingTuple)
        let oldTransaction = pendingTuple.domainModel
        var recipient: UserModel?
        switch oldTransaction.action {
            case .buy:
                recipient = oldTransaction.seller
            case .sell:
                recipient = oldTransaction.buyer
        }
        try await transactionsLocalRepository.replaceQueued(oldTransaction, with: transaction)
        try businessDataContext.commit { confirmedUploads.removeValue(forKey: oldTransaction.id) }
        // Recipient cleanup cannot turn an already committed upload into a retry.
        try? await transactionsLocalRepository.deleteTxRecepient(recipient)

        try await MainActor.run {
            try businessDataContext.capture().check()
            appState.transactions.dispatch { state in
                state.updateList(with: transaction, replacing: oldTransaction.id)
                state.updatingList.remove(id: oldTransaction.id)
            }
        }
    }
}
