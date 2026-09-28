//
//  TransactionHistoryRepositoryImpl.swift
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
import DatabaseKit
import RestClient
import StorageKit
import Targets
import Utility

actor TransactionHistoryRepositoryImpl: TransactionListRepository {
    private struct CachedPage: Codable {
        let records: [DatabaseKit.Transaction.Node]
        let nextPage: Int?
    }
    private struct Snapshot: Codable {
        var pages: [Int: CachedPage]
    }

    private let businessDataContext: BusinessDataContext
    private let target: TransactionsTarget
    private let database: DatabaseKit.Database
    private let mapper: TransactionsMapperProtocol
    private let queryMapper: TransactionListQueryMapperProtocol
    private let keychainStore: AnyStorage<KeychainStore>
    private var generations: [String: UUID] = [:]

    init(target: TransactionsTarget, database: DatabaseKit.Database, mapper: TransactionsMapperProtocol,
         queryMapper: TransactionListQueryMapperProtocol, keychainStore: AnyStorage<KeychainStore>,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.target = target
        self.database = database
        self.mapper = mapper
        self.queryMapper = queryMapper
        self.keychainStore = keychainStore
    }

    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        try await businessDataContext.withCurrentGeneration {
            guard let commodityId = query.commodityId, !commodityId.isEmpty,
                  let seasonId = query.exactSeasonId ?? query.filter.season?.id, !seasonId.isEmpty, page > 0 else {
                throw TransactionHistoryError.invalidQuery
            }

            guard let accountId = accountId else { throw TransactionHistoryError.unavailableCache }

            let search = queryMapper.toDTO(query)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let key = try encoder.encode([accountId, encoder.encode(search).base64EncodedString()]).base64EncodedString()
            if cacheOnly { return try await cachedPage(key: key, page: page, query: query, accountId: accountId) }
            if page == 1 { generations[key] = UUID() }
            let generation = generations[key]
            do {
                let response = try await target.transactionsList(.init(searchData: search, pageData: .init(page: page, pageSize: 20)))
                try Task.checkCancellation()
                try requireAccount(accountId)
                let records = try validatedRecords(response, query: query, page: page)
                let cached = CachedPage(records: records.map(mapper.toDatabaseNode), nextPage: response.pagination.nextPage)
                var snapshot = page == 1 ? Snapshot(pages: [:]) : try await readSnapshot(key: key) ?? Snapshot(pages: [:])
                guard generations[key] == generation else { throw CancellationError() }

                try Task.checkCancellation()
                snapshot.pages[page] = cached
                let record = TransactionHistoryCache(id: key, payload: try JSONEncoder().encode(snapshot))
                // Commit the query evidence and its rows together; queued records/evidence are independent.
                let businessGeneration = try businessDataContext.capture()
                try await database.save { [keychainStore] db in
                    try businessGeneration.whileCurrent {
                        let user: UserModel? = keychainStore.get(.user)
                        guard user?.id == accountId else { throw CancellationError() }

                        for node in cached.records {
                            try node.commodity.group.save(db)
                            try node.commodity.commodity.save(db)
                            if let seller = node.seller { try seller.save(db) }
                            if let buyer = node.buyer { try buyer.save(db) }
                            let existing = try DatabaseKit.Transaction.fetchOne(db, key: node.transaction.id)
                            if existing?.persistingData.state != .onDisk { try node.transaction.save(db) }
                        }
                        try record.save(db)
                    }
                }
                return try await result(cached, query: query, accountId: accountId, includeQueued: page == 1, isCached: false)
            } catch RestClient.RestError.connectionLost {
                try Task.checkCancellation()
                try requireAccount(accountId)
                return try await cachedPage(key: key, page: page, query: query, accountId: accountId)
            }
        }
    }

    private var accountId: String? {
        let user: UserModel? = keychainStore.get(.user)
        return user?.id
    }

    private func requireAccount(_ id: String) throws {
        if accountId != id { throw CancellationError() }
    }

    private func validatedRecords(_ response: ResponseModels.TransactionsInfo, query: TransactionListQuery,
                                  page: Int) throws -> [TransactionModel] {
        let pagination = response.pagination
        guard pagination.page == page, pagination.pageSize > 0, pagination.count >= .zero,
              pagination.totalPages >= 0, pagination.nextPage == nil || pagination.nextPage == page + 1,
              (pagination.nextPage != nil) == (page < pagination.totalPages),
              response.data.count == min(pagination.pageSize, max(0, pagination.count - (page - 1) * pagination.pageSize)),
              pagination.totalPages == (pagination.count + pagination.pageSize - 1) / pagination.pageSize
                || (pagination.count == .zero && pagination.totalPages == 1) else {
            throw TransactionHistoryError.incompleteResponse
        }
        var records: IdentifiedArrayOf<TransactionModel> = []
        for value in response.data {
            let transaction = mapper.toDomain(from: value)
            guard query.matches(transaction), transaction.creationDate != nil else {
                throw TransactionHistoryError.incompleteResponse
            }
            records[id: transaction.id] = transaction
        }
        return Array(records)
    }

    private func readSnapshot(key: String) async throws -> Snapshot? {
        guard let record = try await database.readOne(TransactionHistoryCache.filter(key: key)) else { return nil }

        return try JSONDecoder().decode(Snapshot.self, from: record.payload)
    }

    private func cachedPage(key: String, page: Int, query: TransactionListQuery, accountId: String) async throws -> TransactionListPage {
        guard let cached = try await readSnapshot(key: key)?.pages[page] else { throw TransactionHistoryError.unavailableCache }

        return try await result(cached, query: query, accountId: accountId, includeQueued: page == 1, isCached: true)
    }

    private func result(_ page: CachedPage, query: TransactionListQuery, accountId: String,
                        includeQueued: Bool, isCached: Bool) async throws -> TransactionListPage {
        var records: IdentifiedArrayOf<TransactionModel> = []
        for node in page.records {
            let transaction = mapper.toDomain(from: node)
            guard query.matches(transaction) else { throw TransactionHistoryError.incompleteResponse }

            records[id: transaction.id] = transaction
        }
        if includeQueued {
            let queued = try await database.readAll(DatabaseKit.Transaction.Node.allOnDisk())
            for node in queued {
                let item = mapper.toDomain(from: node)
                guard item.buyer?.id == accountId || item.seller?.id == accountId || item.createdById == accountId,
                      query.matches(item) else { continue }

                records[id: item.id] = item
            }
        }
        try Task.checkCancellation()
        try requireAccount(accountId)
        return .init(list: .init(uniqueElements: TransactionListQuery.creationOrder(Array(records))),
                     nextPage: page.nextPage, isCached: isCached)
    }
}
