//
//  ConversionRequestTests.swift
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

final class ConversionRequestTests: XCTestCase {
    func testCoverageRepeatsCommodityPredicateWithoutBracketsOrStatusFilter() throws {
        let request = RequestModels.HarvestSeasonsList(commodityIds: ["beans", "water", "powder", "oil"], page: 2)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        let router = RequestRouter.HarvestSeasons(request: request)
        let url = try XCTUnwrap(URL(string: "https://example.com/harvest-seasons/"))
        let encoded = try router.encoder.encode(URLRequest(url: url), with: fields)
        let encodedURL = try XCTUnwrap(encoded.url)
        let items = try XCTUnwrap(URLComponents(url: encodedURL, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(items.filter { $0.name == "commodity_id" }.compactMap(\.value), ["beans", "water", "powder", "oil"])
        XCTAssertFalse(items.contains { $0.name == "commodity_id[]" || $0.name == "status" || $0.name == "commodity_group_id" })
        XCTAssertEqual(items.first { $0.name == "page" }?.value, "2")
        XCTAssertTrue(router.addAuth)
    }

    func testRequestCarriesExactInheritedSeasonAndOverrides() throws {
        let request = RequestModels.MakeConversion(recipeId: "recipe", harvestSeasonId: "archived-season",
            inputOverrides: [.init(commodityId: "beans", quantity: 12.5)],
            outputOverrides: [.init(commodityId: "powder", quantity: 7)])
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        XCTAssertEqual(Set(fields.keys), ["recipe_id", "harvest_season_id", "input_overrides", "output_overrides"])
        XCTAssertEqual(fields["harvest_season_id"] as? String, "archived-season")
        XCTAssertEqual((fields["input_overrides"] as? [[String: Any]])?.first?["quantity"] as? Double, 12.5)
        XCTAssertEqual((fields["output_overrides"] as? [[String: Any]])?.first?["commodity_id"] as? String, "powder")
    }
}
