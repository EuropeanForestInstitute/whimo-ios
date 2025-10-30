//
//  TransactionsCacheServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 17.07.2025.
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
import Utility

final class TransactionsCacheServiceImpl: TransactionsCacheService {
    // MARK: - Dependencies
    private let appState: AppState
    private let localRepo: TransactionsLocalRepository

    // MARK: - Init
    init(appState: AppState, localRepo: TransactionsLocalRepository) {
        self.appState = appState
        self.localRepo = localRepo
    }

    // MARK: - TransactionsCacheService
    func fetchTransactions() async throws {
        appState.transactions.dispatch { state in
            state.list.setIsLoading()
        }
        do {
            let pagination: RequestModels.TransactionsList = .initial()
            let transactions = try await localRepo.fetchTransactions(with: pagination)
            let updatingList = appState.transactions.value.updatingList
            let loadedList = transactions.list.map { item in
                guard
                    let updatingItem = updatingList[id: item.id],
                    updatingItem.persistingData.state == .uploading
                else { return item }

                return updatingItem
            }

            appState.transactions.dispatch { state in
                let list: IdentifiedArrayOf<TransactionModel> = .init(uniqueElements: loadedList)
                if !list.isEmpty {
                    state.list = .requested(lastValue: list)
                } else {
                    state.list = .requested(lastValue: nil)
                }
            }
        } catch {
            appState.transactions.dispatch { state in
                state.list = .failed(error: error)
            }
            throw error
        }
    }
}
