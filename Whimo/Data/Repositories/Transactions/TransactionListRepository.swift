//
//  TransactionListRepository.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 19.08.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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

protocol TransactionListRepository {
    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage
}

final class TransactionListRepositoryImpl: TransactionListRepository {
    private let caching: TransactionsCachingRepository
    private let local: TransactionsLocalRepository
    private let history: TransactionListRepository
    private let queryMapper: TransactionListQueryMapperProtocol

    init(
        caching: TransactionsCachingRepository,
        local: TransactionsLocalRepository,
        queryMapper: TransactionListQueryMapperProtocol,
        history: TransactionListRepository
    ) {
        self.caching = caching
        self.local = local
        self.queryMapper = queryMapper
        self.history = history
    }

    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        if query.commodityId != nil {
            return try await history.page(query: query, page: page, cacheOnly: cacheOnly)
        }
        let request = RequestModels.TransactionsList(
            searchData: queryMapper.toDTO(query), pageData: .init(page: page, pageSize: 20)
        )
        if cacheOnly {
            let response = try await local.fetchTransactions(with: request)
            return .init(list: response.list, nextPage: response.pagination.nextPage, isCached: true)
        }
        let response = try await caching.fetchTransactions(with: request)
        var list = response.list
        if page == 1, !response.isCached {
            let queued = try await local.fetchOnDiskTransactions().filter(query.matches)
            for item in queued.reversed() where list[id: item.id] == nil {
                list.insert(item, at: 0)
            }
        }
        return .init(list: list, nextPage: response.pagination.nextPage, isCached: response.isCached)
    }
}
