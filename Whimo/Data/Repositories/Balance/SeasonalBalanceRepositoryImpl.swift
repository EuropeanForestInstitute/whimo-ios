//
//  SeasonalBalanceRepositoryImpl.swift
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
import Targets

actor SeasonalBalanceRepositoryImpl: SeasonalBalanceRepository {
    private struct Snapshot: Codable {
        var pages: [Int: SeasonalBalancePage]

        func validatePairs() throws {
            var pairs = Set<[String]>()
            for row in pages.values.flatMap(\.rows) {
                guard let seasonId = row.season?.id else { continue }
                guard pairs.insert([row.commodity.id, seasonId]).inserted else { throw SeasonalBalanceError.incompleteResponse }

            }
        }
    }

    private struct Observation: Codable {
        let revision: Int64
        let volume: Double
        let traceability: TransactionModel.Traceability?

        var balance: ExactSeasonalBalance { .init(volume: volume, traceability: traceability, isCached: true) }
    }

    private struct SavedBalances: Codable {
        var revision: Int64 = 0
        var pairs: [String: Observation] = [:]
    }

    // The synchronous SQLite closure and cancellation handler cannot hop back to this actor.
    // The lock protects validity only, and is never held across an await.
    private final class RequestGeneration {
        private let lock = NSLock()
        private var isCurrent = true

        func invalidate() { lock.withLock { isCurrent = false } }

        func whileCurrent(_ operation: () throws -> Void) throws {
            try lock.withLock {
                guard isCurrent else { throw CancellationError() }

                try operation()
            }
        }
    }

    private let businessDataContext: BusinessDataContext
    private let target: BalancesTarget
    private let database: DatabaseKit.Database
    private let mapper: SeasonalBalanceMapperProtocol
    private let accountId: () -> String?
    private var generations: [String: RequestGeneration] = [:]

    init(target: BalancesTarget, database: DatabaseKit.Database, mapper: SeasonalBalanceMapperProtocol, accountId: @escaping () -> String?,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.target = target
        self.database = database
        self.mapper = mapper
        self.accountId = accountId
    }

    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        try await businessDataContext.withCurrentGeneration {
            let participant = try participantId()
            let key = try cacheKey(query, participant: participant)
            if cacheOnly {
                let result = try await cachedPage(key: key, page: page)
                try validateSession(participant)
                return result
            }
            do {
                return try await loadPage(query: query, page: page, participant: participant, key: key)
            } catch RestClient.RestError.connectionLost {
                try validateSession(participant)
                let result = try await cachedPage(key: key, page: page)
                try validateSession(participant)
                return result
            }
        }
    }

    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        try await businessDataContext.withCurrentGeneration {
            let participant = try participantId()
            do {
                let query = BalanceListQuery(commodityId: commodityId, exactSeasonId: seasonId)
                let result = try await loadPage(query: query, page: 1, participant: participant,
                                                key: cacheKey(query, participant: participant))
                try validateSession(participant)
                return try result.exactBalance(commodityId: commodityId, seasonId: seasonId)
            } catch {
                guard !(error is CancellationError) else { throw error }

                try validateSession(participant)
                // Read after failure: another successful save may have completed during the request.
                guard let saved = try? await cachedExact(commodityId: commodityId, seasonId: seasonId) else {
                    if case RestClient.RestError.connectionLost = error { throw SeasonalBalanceError.unavailableCache }
                    throw error
                }

                try validateSession(participant)
                return saved
            }
        }
    }

    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        try await businessDataContext.withCurrentGeneration {
            let participant = try participantId()
            let pair = try pairKey(commodityId: commodityId, seasonId: seasonId)
            let records = try await database.readAll(SeasonalBalanceCache.all())
            try validateSession(participant)
            if let record = records.first(where: { $0.id == savedKey(participant) }),
               let saved = try JSONDecoder().decode(SavedBalances.self, from: record.payload).pairs[pair] {
                return saved.balance
            }
            return try legacyBalance(records: records, participant: participant, commodityId: commodityId, seasonId: seasonId)
        }
    }

    private func loadPage(query: BalanceListQuery, page: Int, participant: String, key: String) async throws -> SeasonalBalancePage {
        if page == 1 { generations[key]?.invalidate() }
        let generation = page == 1 ? RequestGeneration() : generations[key] ?? RequestGeneration()
        generations[key] = generation
        return try await withTaskCancellationHandler {
            do {
                return try await fetchAndSave(query: query, page: page, participant: participant, key: key, generation: generation)
            } catch {
                // Database.save wraps closure errors; restore cancellation before exact fallback can handle a failure.
                try generation.whileCurrent { }
                try validateSession(participant)
                throw error
            }
        } onCancel: {
            generation.invalidate()
        }
    }

    private func fetchAndSave(query: BalanceListQuery, page: Int, participant: String, key: String,
                              generation: RequestGeneration) async throws -> SeasonalBalancePage {
        let request = RequestModels.BalancesList(search: query.search, groupId: query.filter.group?.id,
            harvestSeasonId: query.exactSeasonId ?? query.filter.season?.id, commodityId: query.commodityId, page: page)
        let response = try await target.balances(request)
        try validateSession(participant)
        let result = try mapper.toDomain(response, requestedPage: page)
        let observations = try observations(result, query: query)
        try generation.whileCurrent { }

        let savedKey = savedKey(participant)
        let businessGeneration = try businessDataContext.capture()
        try await database.save { [accountId] db in
            try businessGeneration.whileCurrent {
                try generation.whileCurrent {
                    guard accountId() == participant else { throw CancellationError() }

                    let decoder = JSONDecoder()
                    var snapshot = Snapshot(pages: [:])
                    if page != 1, let record = try SeasonalBalanceCache.fetchOne(db, key: key) {
                        snapshot = try decoder.decode(Snapshot.self, from: record.payload)
                    }
                    snapshot.pages[page] = result
                    try snapshot.validatePairs()
                    var saved = SavedBalances()
                    if let record = try SeasonalBalanceCache.fetchOne(db, key: savedKey) {
                        saved = try decoder.decode(SavedBalances.self, from: record.payload)
                    }
                    // SQLite serializes revision allocation and both writes, including across repository instances.
                    saved.revision += 1
                    for (pair, balance) in observations {
                        saved.pairs[pair] = Observation(revision: saved.revision, volume: balance.volume, traceability: balance.traceability)
                    }
                    try SeasonalBalanceCache(id: key, payload: JSONEncoder().encode(snapshot)).save(db)
                    try SeasonalBalanceCache(id: savedKey, payload: JSONEncoder().encode(saved)).save(db)
                    guard accountId() == participant else { throw CancellationError() }

                }
            }
        }
        try generation.whileCurrent { }
        try validateSession(participant)
        return result
    }

    private func observations(_ page: SeasonalBalancePage, query: BalanceListQuery) throws -> [String: ExactSeasonalBalance] {
        guard page.rows.allSatisfy({ row in
            (query.filter.group == nil || query.filter.group?.id == row.commodity.group.id)
                && (query.commodityId == nil || query.commodityId == row.commodity.id)
                && ((query.exactSeasonId ?? query.filter.season?.id).map { $0 == row.season?.id } ?? true)
        }) else { throw SeasonalBalanceError.incompleteResponse }

        if let commodityId = query.commodityId, let seasonId = query.exactSeasonId {
            let balance = try page.exactBalance(commodityId: commodityId, seasonId: seasonId)
            // Search/group restrictions do not prove absence of an exact pair.
            guard !page.rows.isEmpty || (query.search.isEmpty && query.filter.group == nil && query.filter.season == nil) else { return [:] }

            return [try pairKey(commodityId: commodityId, seasonId: seasonId): balance]
        }
        var result: [String: ExactSeasonalBalance] = [:]
        for row in page.rows {
            guard let seasonId = row.season?.id, !row.commodity.id.isEmpty, !seasonId.isEmpty,
                  row.volume.isFinite, row.volume >= 0 else { continue }
            let key = try pairKey(commodityId: row.commodity.id, seasonId: seasonId)
            guard result[key] == nil else { throw SeasonalBalanceError.incompleteResponse }

            result[key] = .init(volume: row.volume, traceability: row.traceability, isCached: page.isCached)
        }
        return result
    }

    private func legacyBalance(records: [SeasonalBalanceCache], participant: String,
                               commodityId: String, seasonId: String) throws -> ExactSeasonalBalance {
        var candidates: [ExactSeasonalBalance] = []
        let pair = try pairKey(commodityId: commodityId, seasonId: seasonId)
        for record in records {
            guard let data = Data(base64Encoded: record.id),
                  let fields = try? JSONDecoder().decode([String?].self, from: data), fields.count == 6,
                  fields[0] == participant,
                  let snapshot = try? JSONDecoder().decode(Snapshot.self, from: record.payload) else { continue }

            let query = BalanceListQuery(search: fields[1] ?? "",
                filter: .init(group: fields[2].map { .init(id: $0, name: "") }), commodityId: fields[4], exactSeasonId: fields[5] ?? fields[3])
            for page in snapshot.pages.values {
                if var balance = try observations(page, query: query)[pair] {
                    balance = .init(volume: balance.volume, traceability: balance.traceability, isCached: true)
                    candidates.append(balance)
                }
            }
        }
        guard let first = candidates.first, candidates.allSatisfy({ $0 == first }) else { throw SeasonalBalanceError.unavailableCache }

        return first
    }

    private func pairKey(commodityId: String, seasonId: String) throws -> String {
        guard !commodityId.isEmpty, !seasonId.isEmpty else { throw SeasonalBalanceError.unavailableCache }

        return try JSONEncoder().encode([commodityId, seasonId]).base64EncodedString()
    }

    private func savedKey(_ participant: String) -> String { "saved-balances:" + participant }

    private func cacheKey(_ query: BalanceListQuery, participant: String) throws -> String {
        let fields = [participant, query.search, query.filter.group?.id, query.filter.season?.id, query.commodityId, query.exactSeasonId]
        return try JSONEncoder().encode(fields).base64EncodedString()
    }

    private func participantId() throws -> String {
        try businessDataContext.capture().check()
        guard let participant = accountId(), !participant.isEmpty else { throw SeasonalBalanceError.unavailableCache }

        return participant
    }

    private func validateSession(_ participant: String) throws {
        try businessDataContext.capture().check()
        guard accountId() == participant else { throw CancellationError() }

    }

    private func cachedPage(key: String, page: Int) async throws -> SeasonalBalancePage {
        guard let record = try await database.readOne(SeasonalBalanceCache.filter(key: key)),
              var result = try JSONDecoder().decode(Snapshot.self, from: record.payload).pages[page] else {
            throw SeasonalBalanceError.unavailableCache
        }
        result.isCached = true
        return result
    }
}
