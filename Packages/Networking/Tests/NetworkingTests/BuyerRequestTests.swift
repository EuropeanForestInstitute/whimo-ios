//
//  BuyerRequestTests.swift
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
import Targets
import RestClient

final class BuyerRequestTests: XCTestCase {
    func testOneFullVolumeRequestEncodesCapturedSeason() throws {
        let request = RequestModels.CreateTransaction.Downstream.TransactionData(
            commodityId: "beans", volume: "300", location: nil, farmLatitude: nil, farmLongitude: nil,
            action: .buy, recipient: .name("supplier-fixture"), harvestSeasonId: "captured-season"
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        XCTAssertEqual(Set(payload.keys), ["commodity_id", "volume", "action", "recipient", "harvest_season_id"])
        XCTAssertEqual(payload["harvest_season_id"] as? String, "captured-season")
        XCTAssertEqual(payload["volume"] as? String, "300")
        XCTAssertEqual(payload["action"] as? String, "buying")
    }
    func testSellerEncodesOnlyOneFullVolumeSaleWithCapturedSeason() throws {
        let request = RequestModels.CreateTransaction.Downstream.TransactionData(
            commodityId: "beans", volume: "300", location: nil, farmLatitude: nil, farmLongitude: nil,
            action: .sell, recipient: .name("buyer-fixture"), harvestSeasonId: "captured-season"
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request)) as? [String: Any])
        XCTAssertEqual(Set(payload.keys), ["commodity_id", "volume", "action", "recipient", "harvest_season_id"])
        XCTAssertEqual(payload["harvest_season_id"] as? String, "captured-season")
        XCTAssertEqual(payload["volume"] as? String, "300")
        XCTAssertEqual(payload["action"] as? String, "selling")
    }

}
