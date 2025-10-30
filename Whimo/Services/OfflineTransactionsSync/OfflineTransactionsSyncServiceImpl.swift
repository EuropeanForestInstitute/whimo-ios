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
final class OfflineTransactionsSyncServiceImpl: OfflineTransactionsSyncService {
    // MARK: - PendingTransaction
    enum PendingTransaction: AutoStringConvertible {
        case producer(RequestModels.CreateTransaction.Producer)
        case downstream(RequestModels.CreateTransaction.Downstream)
    }

    typealias PendingTuple = (domainModel: TransactionModel, requestModel: PendingTransaction)

    // MARK: - Dependencies
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
        transactionsMapper: any TransactionsMapperProtocol
    ) {
        self.appState = appState
        self.transactionsLocalRepository = transactionsLocalRepository
        self.transactionsOfflineMapper = transactionsOfflineMapper
        self.transactionsTarget = transactionsTarget
        self.transactionsMapper = transactionsMapper
    }

    // MARK: - OfflineTransactionsSyncService
    func syncTransactions() async throws {
        let pendingTuples = try await fetchTransactions()
        for tuple in pendingTuples {
            try await handlePendingTransactrion(tuple)
        }
    }
}

// MARK: - Private Methods
private extension OfflineTransactionsSyncServiceImpl {
    func fetchTransactions() async throws -> Zip2Sequence<IdentifiedArrayOf<TransactionModel>, [OfflineTransactionsSyncServiceImpl.PendingTransaction]> {
        let onDiskItems = try await transactionsLocalRepository.fetchOnDiskTransactions()
        let pendingTransactions: [PendingTransaction] = onDiskItems.reduce(into: []) { partialResult, transaction in
            switch transaction.type {
                case .producer:
                    let transaction: RequestModels.CreateTransaction.Producer = transactionsOfflineMapper.toDTO(from: transaction)
                    partialResult.append(.producer(transaction))
                case .downstream:
                    let transaction: RequestModels.CreateTransaction.Downstream = transactionsOfflineMapper.toDTO(from: transaction)
                    partialResult.append(.downstream(transaction))
            }
        }
        let pendingTupleZip = zip(onDiskItems, pendingTransactions)

        return pendingTupleZip
    }

    #warning("Add error handling to indicate that this tx uploading ended with error")
    func handlePendingTransactrion(_ pendingTuple: PendingTuple) async throws {
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

        let response: ResponseModels.TransactionInfo
        switch pendingTuple.requestModel {
            case .producer(let request):
                response = try await transactionsTarget.createProducerTransaction(request)
            case .downstream(let request):
                response = try await transactionsTarget.createDownstreamTransaction(request)
        }
        let transaction = transactionsMapper.toDomain(from: response.data)
        let oldTransaction = pendingTuple.domainModel
        var recipient: UserModel?
        switch oldTransaction.action {
            case .buy:
                recipient = oldTransaction.seller
            case .sell:
                recipient = oldTransaction.buyer
        }
        try await transactionsLocalRepository.delete(oldTransaction)
        try await transactionsLocalRepository.deleteTxRecepient(recipient)
        try await transactionsLocalRepository.save(transaction)

        var currentList: IdentifiedArrayOf<TransactionModel> = appState.transactions.value.list.value ?? []
        currentList.remove(id: oldTransaction.id)
        let updatedList: IdentifiedArrayOf<TransactionModel> = [transaction] + currentList
        appState.transactions.dispatch { state in
            state.list = .loaded(value: updatedList)
            state.updatingList.remove(id: oldTransaction.id)
        }
    }
}
