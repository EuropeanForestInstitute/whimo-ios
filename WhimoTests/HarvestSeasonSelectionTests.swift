//
//  HarvestSeasonSelectionTests.swift
//  WhimoTests
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

import Combine
import Contacts
import CoreLocation
import XCTest
import UserNotifications

import FactoryKit

import CommonUI
import RestClient
import Utility
@testable import Whimo

final class HarvestSeasonSelectionTests: XCTestCase {
    func testConcreteSelectionFormatsPeriodUsingGregorianUTCYears() {
        let harvestSeason = HarvestSeason(
            id: "2025-season",
            startDate: Date(timeIntervalSince1970: 1_767_211_200),
            endDate: Date(timeIntervalSince1970: 1_798_747_200),
            status: .active
        )

        let selection = HarvestSeasonSelection.harvestSeason(harvestSeason)

        XCTAssertEqual(selection.periodTitle, "2025/26")
    }

    func testSelectionIdentityDistinguishesAllAndRemainsStableForConcreteID() {
        let originalHarvestSeason = HarvestSeason(
            id: "all",
            startDate: Date(timeIntervalSince1970: 1_767_225_600),
            endDate: Date(timeIntervalSince1970: 1_798_761_600),
            status: .active
        )
        let updatedHarvestSeason = HarvestSeason(
            id: "all",
            startDate: Date(timeIntervalSince1970: 1_735_689_600),
            endDate: Date(timeIntervalSince1970: 1_767_225_600),
            status: .past
        )

        let originalSelection = HarvestSeasonSelection.harvestSeason(originalHarvestSeason)
        let updatedSelection = HarvestSeasonSelection.harvestSeason(updatedHarvestSeason)

        XCTAssertNotEqual(HarvestSeasonSelection.all.id, originalSelection.id)
        XCTAssertEqual(originalSelection.id, updatedSelection.id)
        XCTAssertEqual(originalSelection, updatedSelection)
    }
}
