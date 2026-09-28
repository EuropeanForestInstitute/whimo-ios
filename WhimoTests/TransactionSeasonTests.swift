//
//  TransactionSeasonTests.swift
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
import DatabaseKit
import GRDB
import RestClient
import Targets
@testable import Whimo

final class TransactionSeasonTests: XCTestCase {
    func testStatusResponseRequiresOrdinaryAndExplicitAutomaticOutcome() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let ordinary = Self.pendingJSON.replacingOccurrences(of: "pending", with: "accepted")
        let json = "{\"data\":{\"transaction\":\(ordinary),\"automatic_transaction\":null}}"
        let response = try decoder.decode(ResponseModels.UpdateTransactionStatus.self, from: Data(json.utf8))
        XCTAssertEqual(response.data.transaction.id, "transaction")
        XCTAssertNil(response.data.automaticTransaction)
        for incomplete in ["{\"data\":{}}", "{\"data\":{\"transaction\":\(ordinary)}}"] {
            XCTAssertThrowsError(try decoder.decode(ResponseModels.UpdateTransactionStatus.self, from: Data(incomplete.utf8)))
        }
    }

    func testPendingTransactionSeasonSurvivesMapperAndDatabaseRoundTrip() async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ResponseModels.Transaction.self, from: Data(Self.pendingJSON.utf8))
        let mapper = TransactionsMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper(),
                                        seasonMapper: SeasonCatalogueMapper())
        let transaction = mapper.toDomain(from: response)
        XCTAssertEqual(transaction.harvestSeasonId, "opaque-season")
        XCTAssertEqual(transaction.harvestSeason?.name, "Cocoa special harvest 2025/26")
        XCTAssertEqual(transaction.harvestSeason?.status, .past)
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let node = mapper.toDatabaseNode(from: transaction)
        try await database.save { db in
            try node.commodity.group.save(db)
            try node.commodity.commodity.save(db)
            try node.transaction.save(db)
        }
        let nodes = try await database.readAll(DatabaseKit.Transaction.Node.all())
        let restored = mapper.toDomain(from: try XCTUnwrap(nodes.first))
        XCTAssertEqual(restored.harvestSeason, transaction.harvestSeason)
        XCTAssertEqual(restored.harvestSeasonId, "opaque-season")
        XCTAssertEqual(restored.status, .pending)
    }

    func testLegacyResponseOmitsUnavailableMetadataWithoutInventingValues() throws {
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(Self.pendingJSON.utf8)) as? [String: Any])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        for missingValue in [nil, NSNull()] as [Any?] {
            payload["harvest_season"] = missingValue
            let response = try decoder.decode(ResponseModels.Transaction.self, from: JSONSerialization.data(withJSONObject: payload))
            XCTAssertNil(response.harvestSeason)
            XCTAssertNil(response.traceability)
            XCTAssertNil(response.commodity.balance)
            XCTAssertNil(response.commodity.hasRecipe)
        }
        payload["harvest_season"] = ["id": "opaque-only"]
        XCTAssertThrowsError(try decoder.decode(ResponseModels.Transaction.self, from: JSONSerialization.data(withJSONObject: payload)))
        payload.removeValue(forKey: "harvest_season")
        payload.removeValue(forKey: "is_automatic")
        XCTAssertThrowsError(try decoder.decode(ResponseModels.Transaction.self, from: JSONSerialization.data(withJSONObject: payload)))
    }

    func testInvalidSeasonDatesRetainIdentityWithUnavailablePresentation() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ResponseModels.Transaction.self, from: Data(
            Self.pendingJSON.replacingOccurrences(of: "2025-09-01", with: "invalid").utf8
        ))
        let mapper = TransactionsMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper(),
                                        seasonMapper: SeasonCatalogueMapper())
        let transaction = mapper.toDomain(from: response)
        XCTAssertEqual(transaction.harvestSeasonId, "opaque-season")
        XCTAssertNil(transaction.harvestSeason)
        XCTAssertNil(TransactionSeasonPresentation(season: nil).dateRange(locale: Locale(identifier: "en_US")))
    }

    func testPopupUsesStoredStatusAndInclusiveLastDayInGregorianUTC() throws {
        let mapper = SeasonCatalogueMapper()
        for status in [ResponseModels.HarvestSeason.Status.active, .past, .archived] {
            let season = try mapper.toDomain(from: .init(
                id: "opaque", name: "A very long backend season name", startDate: "2025-09-01", endDate: "2026-09-01", status: status
            ))
            let presentation = TransactionSeasonPresentation(season: season)
            XCTAssertEqual(presentation.title, "2025/26")
            XCTAssertEqual(presentation.dateRange(locale: Locale(identifier: "en_US")), "Sep 1, 2025 – Aug 31, 2026")
            XCTAssertTrue(presentation.accessibilityLabel.contains("A very long backend season name"))
            XCTAssertEqual(season.status.rawValue, status.rawValue)
        }
    }

    func testExportQueryMapperKeepsAllCriteria() throws {
        let season = try SeasonCatalogueMapper().toDomain(from: .init(
            id: "season", name: "Cocoa 2025/26", startDate: "2025-09-01", endDate: "2026-09-01", status: .past
        ))
        let query = TransactionListQuery(search: "cocoa", createdAtFrom: Date(timeIntervalSince1970: 0),
                                         createdAtTo: Date(timeIntervalSince1970: 86400), action: .sell,
                                         filter: .init(group: .init(id: "group", name: "Cocoa"), season: season))
        let criteria = TransactionListQueryMapper().toDTO(query)
        XCTAssertEqual(criteria.search, "cocoa")
        XCTAssertEqual(criteria.commodityGroupId, "group")
        XCTAssertEqual(criteria.harvestSeasonId, "season")
        XCTAssertEqual(criteria.action, .sell)
        XCTAssertEqual(criteria.createdAtFrom, "1970-01-01T00:00:00.000Z")
        XCTAssertEqual(criteria.createdAtTo, "1970-01-02T00:00:00.000Z")
        XCTAssertEqual(TransactionListQueryMapper().toDTO(.init()), .empty)
    }

    private static let pendingJSON = """
    {
      "id":"transaction", "created_at":"2026-01-02T00:00:00Z", "type":"downstream",
      "status":"pending", "action":"buying", "volume":12,
      "is_buying_from_farmer":false, "is_automatic":false,
      "commodity":{"id":"commodity", "code":"1801", "name":"Cocoa", "unit":"kg",
        "group":{"id":"group", "name":"Cocoa"}},
      "harvest_season":{"id":"opaque-season", "name":"Cocoa special harvest 2025/26",
        "start_date":"2025-09-01", "end_date":"2026-09-01", "status":"past"}
    }
    """
}
