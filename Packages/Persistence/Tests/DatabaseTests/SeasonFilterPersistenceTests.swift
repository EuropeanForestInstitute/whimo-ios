//
//  SeasonFilterPersistenceTests.swift
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

import XCTest
import GRDB
@testable import DatabaseKit

final class SeasonFilterPersistenceTests: XCTestCase {
    func testUpgradePreservesQueuedTransactionAndEvidence() async throws {
        let schema = try DatabaseImpl(writer: DatabaseQueue())
        let legacy = try DatabaseQueue()
        try schema.migrator.migrate(legacy, upTo: "create_notifications_settings")
        try await legacy.write { db in
            try db.execute(sql: "INSERT INTO commodityGroup (id, name) VALUES ('group', 'Cocoa')")
            try db.execute(sql: """
                INSERT INTO commodity (id, code, name, unit, hasRecipe, commodityGroupId)
                VALUES ('commodity', 'COC', 'Cocoa', 'kg', 0, 'group')
                """)
            let type = try XCTUnwrap(String(data: JSONEncoder().encode(Transaction.TransactionType.downstream), encoding: .utf8))
            let evidence = Transaction.PersistingData.onDisk(farmLocationFile: .init(
                fileURL: URL(fileURLWithPath: "/tmp/queued-evidence.geojson"), fileName: "evidence.geojson", mimeType: "application/geo+json"
            ))
            let persisted = try XCTUnwrap(String(data: JSONEncoder().encode(evidence), encoding: .utf8))
            try db.execute(sql: """
                INSERT INTO "transaction" (id, createdAt, type, status, action, volume, isBuyingFromFarmer, commodityId, persistingData)
                VALUES ('queued', '2026-01-01', ?, 'pending', 'buying', 12, 0, 'commodity', ?)
                """, arguments: [type, persisted])
        }
        let upgraded = try DatabaseImpl(writer: legacy)
        let rows = try await upgraded.readAll(Transaction.Node.allOnDisk())
        XCTAssertEqual(rows.count, 1)
        let row = try XCTUnwrap(rows.first?.transaction)
        XCTAssertEqual(row.id, "queued")
        XCTAssertEqual(row.volume, 12)
        XCTAssertNil(row.harvestSeasonId)
        XCTAssertEqual(row.persistingData.farmLocationFile?.fileName, "evidence.geojson")
        XCTAssertEqual(row.persistingData.farmLocationFile?.fileURL.path, "/tmp/queued-evidence.geojson")
        _ = try await upgraded.save(SeasonCatalogueCache(id: "groups", payload: Data("[]".utf8)))
        let afterCache = try await upgraded.readAll(Transaction.Node.allOnDisk())
        XCTAssertEqual(afterCache, rows)
    }

    func testMetadataUpgradePreservesQueuedAndSynchronizedRecords() async throws {
        let schema = try DatabaseImpl(writer: DatabaseQueue())
        var migrator = schema.migrator
        migrator.eraseDatabaseOnSchemaChange = false
        let legacy = try DatabaseQueue()
        try migrator.migrate(legacy, upTo: "add_season_catalogue_and_transaction_filter")
        try await legacy.write { db in
            try db.execute(sql: "INSERT INTO commodityGroup (id, name) VALUES ('group', 'Cocoa')")
            try db.execute(sql: """
                INSERT INTO commodity (id, code, name, unit, hasRecipe, commodityGroupId)
                VALUES ('commodity', 'COC', 'Cocoa', 'kg', 0, 'group')
                """)
            try User(id: "recipient", username: "Test recipient", gadgets: []).save(db)
            let type = try XCTUnwrap(String(data: JSONEncoder().encode(
                Transaction.TransactionType.producer(inviteRecipient: .email("fixture@example.invalid"))
            ), encoding: .utf8))
            let attachment = Transaction.PersistingData.File(
                fileURL: URL(fileURLWithPath: "/tmp/fixture.geojson"), fileName: "fixture.geojson", mimeType: "application/geo+json"
            )
            for (identifier, state) in [("queued", Transaction.PersistingData.onDisk(farmLocationFile: attachment)),
                                        ("synchronized", .sync(farmLocationFile: attachment))] {
                let persisted = try XCTUnwrap(String(data: JSONEncoder().encode(state), encoding: .utf8))
                try db.execute(sql: """
                    INSERT INTO "transaction"
                    (id, createdAt, type, status, action, volume, isBuyingFromFarmer, commodityId,
                     sellerId, persistingData, harvestSeasonId)
                    VALUES (?, '2026-01-01', ?, 'pending', 'buying', 12, 0, 'commodity', 'recipient', ?, 'stored-id')
                    """, arguments: [identifier, type, persisted])
            }
        }
        try migrator.migrate(legacy)
        let upgraded = try DatabaseImpl(writer: legacy)
        let rows = try await upgraded.readAll(Transaction.Node.all())
        XCTAssertEqual(Set(rows.map { $0.transaction.id }), ["queued", "synchronized"])
        for node in rows {
            XCTAssertEqual(node.transaction.harvestSeasonId, "stored-id")
            XCTAssertNil(node.transaction.harvestSeason)
            XCTAssertEqual(node.transaction.type, .producer(inviteRecipient: .email("fixture@example.invalid")))
            XCTAssertEqual(node.seller?.id, "recipient")
            XCTAssertEqual(node.transaction.persistingData.farmLocationFile?.fileName, "fixture.geojson")
            XCTAssertEqual(node.transaction.persistingData.farmLocationFile?.fileURL.path, "/tmp/fixture.geojson")
        }
        let queued = try await upgraded.readAll(Transaction.Node.allOnDisk())
        XCTAssertEqual(queued.map { $0.transaction.id }, ["queued"])
    }

    func testBalanceCacheUpgradePreservesQueueAndFlushesAccountCache() async throws {
        let schema = try DatabaseImpl(writer: DatabaseQueue())
        var migrator = schema.migrator
        migrator.eraseDatabaseOnSchemaChange = false
        let legacy = try DatabaseQueue()
        try migrator.migrate(legacy, upTo: "add_transaction_season_metadata")
        try await legacy.write { db in
            try db.execute(sql: "INSERT INTO commodityGroup (id, name) VALUES ('group', 'Cocoa')")
            try db.execute(sql: """
                INSERT INTO commodity (id, code, name, unit, hasRecipe, commodityGroupId)
                VALUES ('commodity', 'COC', 'Cocoa', 'kg', 0, 'group')
                """)
            try User(id: "recipient", username: "Test recipient", gadgets: []).save(db)
            let type = try XCTUnwrap(String(data: JSONEncoder().encode(
                Transaction.TransactionType.producer(inviteRecipient: .email("fixture@example.invalid"))
            ), encoding: .utf8))
            let attachment = Transaction.PersistingData.File(
                fileURL: URL(fileURLWithPath: "/tmp/fixture.geojson"), fileName: "fixture.geojson", mimeType: "application/geo+json"
            )
            for (identifier, state) in [("queued", Transaction.PersistingData.onDisk(farmLocationFile: attachment)),
                                        ("synchronized", .sync(farmLocationFile: attachment))] {
                let persisted = try XCTUnwrap(String(data: JSONEncoder().encode(state), encoding: .utf8))
                try db.execute(sql: """
                    INSERT INTO "transaction"
                    (id, createdAt, type, status, action, volume, isBuyingFromFarmer, commodityId,
                     sellerId, persistingData, harvestSeasonId)
                    VALUES (?, '2026-01-01', ?, 'pending', 'buying', 12, 0, 'commodity', 'recipient', ?, 'stored-id')
                    """, arguments: [identifier, type, persisted])
            }
        }
        try migrator.migrate(legacy)
        let upgraded = try DatabaseImpl(writer: legacy)
        let rows = try await upgraded.readAll(Transaction.Node.all())
        XCTAssertEqual(Set(rows.map { $0.transaction.id }), ["queued", "synchronized"])
        for node in rows {
            XCTAssertEqual(node.transaction.harvestSeasonId, "stored-id")
            XCTAssertNil(node.transaction.harvestSeason)
            XCTAssertEqual(node.transaction.type, .producer(inviteRecipient: .email("fixture@example.invalid")))
            XCTAssertEqual(node.seller?.id, "recipient")
            XCTAssertEqual(node.transaction.persistingData.farmLocationFile?.fileName, "fixture.geojson")
            XCTAssertEqual(node.transaction.persistingData.farmLocationFile?.fileURL.path, "/tmp/fixture.geojson")
        }
        try await upgraded.save(SeasonalBalanceCache(id: "balance-query", payload: Data("fixture".utf8)))
        let cache = try await upgraded.readOne(SeasonalBalanceCache.filter(key: "balance-query"))
        XCTAssertEqual(cache?.payload, Data("fixture".utf8))
        let queued = try await upgraded.readAll(Transaction.Node.allOnDisk())
        XCTAssertEqual(queued.map { $0.transaction.id }, ["queued"])
        try await upgraded.flush()
        let cleared = try await upgraded.readOne(SeasonalBalanceCache.filter(key: "balance-query"))
        XCTAssertNil(cleared)
    }

    func testHistoryCacheUpgradePreservesQueuedEvidenceAndParticipatesInAccountCleanup() async throws {
        let schema = try DatabaseImpl(writer: DatabaseQueue())
        var migrator = schema.migrator
        migrator.eraseDatabaseOnSchemaChange = false
        let legacy = try DatabaseQueue()
        try migrator.migrate(legacy, upTo: "add_seasonal_balance_cache")
        let attachment = Transaction.PersistingData.File(
            fileURL: URL(fileURLWithPath: "/tmp/history-evidence.geojson"), fileName: "evidence.geojson", mimeType: "application/geo+json")
        try await legacy.write { db in
            try CommodityGroup(id: "group", name: "Coffee").save(db)
            try Commodity(id: "bean", code: "0901", name: "Cherry", unit: "kg", balance: nil,
                          commodityGroupId: "group", hasRecipe: false).save(db)
            try User(id: "account", username: "Fixture", gadgets: []).save(db)
            try Transaction(id: "queued", createdAt: "2026-01-01", expiresAt: nil, updatedAt: nil, type: .downstream,
                            status: .pending, action: .sell, traceability: nil, location: nil,
                            farmLatitude: nil, farmLongitude: nil, transactionLatitude: nil, transactionLongitude: nil,
                            volume: 12, isBuyingFromFarmer: false, commodityId: "bean", sellerId: "account", buyerId: nil,
                            createdById: "account", persistingData: .onDisk(farmLocationFile: attachment), harvestSeasonId: "past").save(db)
        }
        try migrator.migrate(legacy)
        let upgraded = try DatabaseImpl(writer: legacy)
        let queue = try await upgraded.readAll(Transaction.Node.allOnDisk())
        XCTAssertEqual(queue.map { $0.transaction.id }, ["queued"])
        XCTAssertEqual(queue.first?.transaction.persistingData.farmLocationFile, attachment)
        XCTAssertEqual(queue.first?.transaction.harvestSeasonId, "past")
        XCTAssertEqual(queue.first?.seller?.id, "account")
        try await upgraded.save(TransactionHistoryCache(id: "account-pair", payload: Data("history".utf8)))
        let saved = try await upgraded.readOne(TransactionHistoryCache.filter(key: "account-pair"))
        XCTAssertEqual(saved?.payload, Data("history".utf8))
        try await upgraded.flush()
        let cleared = try await upgraded.readOne(TransactionHistoryCache.filter(key: "account-pair"))
        XCTAssertNil(cleared)
    }

    func testCachedTransactionQueryCombinesGroupSeasonSearchDateAndAction() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        try await database.save { db in
            for group in ["cocoa", "coffee"] {
                try CommodityGroup(id: group, name: group).save(db)
                try Commodity(id: group, code: group, name: group, unit: "kg", balance: nil,
                              commodityGroupId: group, hasRecipe: false).save(db)
            }
            for (id, group, season, action, date) in [
                ("matching", "cocoa", "old", Transaction.Action.buy, "2026-01-02"),
                ("other-season", "cocoa", "new", .buy, "2026-01-02"),
                ("other-group", "coffee", "old", .buy, "2026-01-02"),
                ("other-action", "cocoa", "old", .sell, "2026-01-02"),
                ("other-date", "cocoa", "old", .buy, "2025-01-02")
            ] {
                try Transaction(id: id, createdAt: date, expiresAt: nil, updatedAt: nil, type: .downstream,
                                status: .accepted, action: action, traceability: nil, location: nil,
                                farmLatitude: nil, farmLongitude: nil, transactionLatitude: nil, transactionLongitude: nil,
                                volume: 1, isBuyingFromFarmer: false, commodityId: group, sellerId: nil,
                                buyerId: nil, createdById: nil, persistingData: .sync(), harvestSeasonId: season).save(db)
            }
        }
        let combined = try await database.readAll(Transaction.Node.filter(
            searchText: "coc", action: "buying", dateFrom: "2026-01-01", dateTo: "2026-01-31",
            commodityGroupId: "cocoa", harvestSeasonId: "old"
        ))
        XCTAssertEqual(combined.map { $0.transaction.id }, ["matching"])
        let groupOnly = try await database.readAll(Transaction.Node.filter(searchText: "", commodityGroupId: "cocoa"))
        XCTAssertEqual(groupOnly.count, 4)
        let all = try await database.readAll(Transaction.Node.filter(searchText: ""))
        XCTAssertEqual(all.count, 5)
    }
}
