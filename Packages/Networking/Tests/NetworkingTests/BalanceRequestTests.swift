//
//  BalanceRequestTests.swift
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
import Networking
import RestClient
import Targets

final class BalanceRequestTests: XCTestCase {
    func testBalanceUsesDeployedCommodityGroupPredicateAndOmitsDefaultSeason() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let query = RequestModels.BalancesList(search: "cocoa", groupId: "group", harvestSeasonId: "past", commodityId: "bean", page: 2)
        let data = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(query)) as? [String: Any])
        XCTAssertEqual(data["commodity_group_id"] as? String, "group")
        XCTAssertEqual(data["harvest_season_id"] as? String, "past")
        XCTAssertEqual(data["commodity_id"] as? String, "bean")
        XCTAssertEqual(data["search"] as? String, "cocoa")
        XCTAssertEqual(data["page"] as? Int, 2)
        XCTAssertEqual(data["page_size"] as? Int, 20)
        XCTAssertNil(data["group_id"])
        let defaults = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(RequestModels.BalancesList())) as? [String: Any])
        XCTAssertNil(defaults["group_id"])
        XCTAssertNil(defaults["commodity_group_id"])
        XCTAssertNil(defaults["harvest_season_id"])
        XCTAssertNil(defaults["harvest_season_status"])
        let router = RequestRouter.Balances(request: query)
        XCTAssertEqual(router.path, "/commodities/balances/")
        XCTAssertEqual(router.method, .get)
        XCTAssertTrue(router.addAuth)
    }
}
