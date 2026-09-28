//
//  TransactionFilterRequestTests.swift
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
import RestClient
import Targets
import Networking

final class TransactionFilterRequestTests: XCTestCase {
    func testExactHistoryEncodesPairAndCreationOrderingWithoutLifecycleRestrictions() throws {
        let request = RequestModels.TransactionsList(searchData: .init(
            search: nil, createdAtFrom: nil, createdAtTo: nil, action: nil, buyerData: nil,
            harvestSeasonId: "season-2", commodityId: "commodity-1", orderings: "-created_at"
        ))
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        XCTAssertEqual(payload["commodity_id"] as? String, "commodity-1")
        XCTAssertEqual(payload["harvest_season_id"] as? String, "season-2")
        XCTAssertEqual(payload["orderings"] as? String, "-created_at")
        for key in ["action", "status", "buyer_id", "commodity_group_id", "harvest_season_status"] {
            XCTAssertNil(payload[key], key)
        }
    }

    func testGroupAndSeasonCombineWithExistingCriteria() throws {
        let request = RequestModels.TransactionsList(searchData: .init(
            search: "cocoa", createdAtFrom: "2026-01-01", createdAtTo: "2026-02-01",
            action: .buy, buyerData: nil, commodityGroupId: "group-1", harvestSeasonId: "season-2"
        ))
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        XCTAssertEqual(payload["commodity_group_id"] as? String, "group-1")
        XCTAssertEqual(payload["harvest_season_id"] as? String, "season-2")
        XCTAssertEqual(payload["search"] as? String, "cocoa")
        XCTAssertEqual(payload["action"] as? String, "buying")
        XCTAssertEqual(payload["created_at_from"] as? String, "2026-01-01")
        XCTAssertEqual(payload["created_at_to"] as? String, "2026-02-01")
        XCTAssertNil(payload["harvest_season_status"])
    }

    func testCSVUsesEveryListPredicateWithoutPagination() throws {
        let criteria = RequestModels.TransactionsList.SearchData(
            search: "cocoa", createdAtFrom: "2026-01-01", createdAtTo: "2026-02-01",
            action: .buy, buyerData: nil, commodityGroupId: "group-1", harvestSeasonId: "season-2"
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let request = RequestModels.DownloadCSV(searchData: criteria)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: String])
        XCTAssertEqual(payload, ["search": "cocoa", "created_at_from": "2026-01-01", "created_at_to": "2026-02-01",
                                 "action": "buying", "commodity_group_id": "group-1", "harvest_season_id": "season-2"])
        let router = RequestRouter.Transactions.downloadCSV(request)
        XCTAssertEqual(router.path, "/transactions/download/csv/")
        XCTAssertTrue(router.addAuth)
        XCTAssertNotNil(router.parameters)
        let chain = RequestRouter.Transactions.downloadCSV(.init(transactionId: "transaction"))
        XCTAssertEqual(chain.path, "/transactions/transaction/download/csv/")
        XCTAssertNil(chain.parameters)
    }

    func testAllOmitsGroupSeasonAndStatus() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(
            RequestModels.TransactionsList.initial()
        )) as? [String: Any])
        XCTAssertNil(payload["commodity_group_id"])
        XCTAssertNil(payload["harvest_season_id"])
        XCTAssertNil(payload["harvest_season_status"])
    }
}
