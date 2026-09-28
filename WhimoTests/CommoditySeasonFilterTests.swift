//
//  CommoditySeasonFilterTests.swift
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
@testable import Whimo

@MainActor
final class CommoditySeasonFilterTests: XCTestCase {
    func testOutOfOrderSeasonResponsesAndGroupReset() async {
        let catalogue = ControlledSeasonCatalogue()
        let sheet = CommoditySeasonFilterViewModel(applied: .init(), catalogue: catalogue) { _ in }
        sheet.selectGroup(.init(id: "cocoa", name: "Cocoa"))
        let old = Task { await sheet.loadSeasons() }
        let first = await catalogue.nextCall()
        sheet.selectGroup(.init(id: "coffee", name: "Coffee"))
        let current = Task { await sheet.loadSeasons() }
        let second = await catalogue.nextCall()
        let season = HarvestSeason(id: "coffee-season", name: "Coffee", startDate: .distantPast, endDate: .distantFuture, status: .past)
        await catalogue.complete(second, seasons: [season])
        await current.value
        sheet.selectSeason(season)
        XCTAssertEqual(sheet.draft.season?.id, "coffee-season")
        await catalogue.complete(first, seasons: [])
        await old.value
        XCTAssertEqual(sheet.seasons.map(\.id), ["coffee-season"])
        XCTAssertEqual(sheet.draft.group?.id, "coffee")
        sheet.selectGroup(nil)
        XCTAssertNil(sheet.draft.season)
        XCTAssertTrue(sheet.seasons.isEmpty)
    }

    func testDraftResetDismissAndApply() async {
        let group = CatalogueGroup(id: "cocoa", name: "Cocoa")
        var applied = CommoditySeasonFilter(group: group)
        let catalogue = FilterCatalogueStub()
        var sheet = CommoditySeasonFilterViewModel(applied: applied, catalogue: catalogue) { applied = $0 }
        XCTAssertFalse(sheet.canApply)
        XCTAssertTrue(sheet.canReset)
        sheet.reset()
        XCTAssertTrue(sheet.canApply)
        XCTAssertFalse(sheet.canReset)
        XCTAssertEqual(applied.group?.id, "cocoa")
        // Ordinary dismissal drops the draft; reopening starts from the applied filter.
        sheet = .init(applied: applied, catalogue: catalogue) { applied = $0 }
        XCTAssertEqual(sheet.draft.group?.id, "cocoa")
        sheet.reset()
        sheet.apply()
        XCTAssertTrue(applied.isEmpty)
    }

    func testAllGroupsDisablesSeasonAndChangingGroupResetsIt() {
        let group = CatalogueGroup(id: "cocoa", name: "Cocoa")
        let season = HarvestSeason(id: "opaque", name: "Cocoa 25/26", startDate: .distantPast, endDate: .distantFuture, status: .archive)
        var filter = CommoditySeasonFilter(group: group, season: season)
        filter.selectGroup(.init(id: "coffee", name: "Coffee"))
        XCTAssertNil(filter.season)
        filter.selectGroup(nil)
        filter.selectSeason(season)
        XCTAssertNil(filter.group)
        XCTAssertNil(filter.season)
        XCTAssertTrue(CommoditySeasonFilter(season: season).isEmpty)
    }

    func testInitialCatalogueIncludesGroupsWithNoBalance() async {
        let sheet = CommoditySeasonFilterViewModel(applied: .init(), catalogue: FilterCatalogueStub()) { _ in }
        await sheet.load()
        XCTAssertEqual(sheet.groups.map(\.id), ["empty-balance", "cocoa"])
        XCTAssertTrue(sheet.draft.isEmpty)
        XCTAssertFalse(sheet.canApply)
        XCTAssertFalse(sheet.canReset)
    }
}

private struct FilterCatalogueStub: SeasonCatalogueInteractor {
    func groups() async throws -> CatalogueResult<CatalogueGroup> {
        .init(values: [.init(id: "empty-balance", name: "Coffee"), .init(id: "cocoa", name: "Cocoa")], isCached: false)
    }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> {
        .init(values: [], isCached: false)
    }
}

private actor ControlledSeasonCatalogue: SeasonCatalogueInteractor {
    private var continuations: [String: CheckedContinuation<CatalogueResult<HarvestSeason>, Error>] = [:]
    private var calls: [String] = []
    private var waiter: CheckedContinuation<String, Never>?

    func groups() async throws -> CatalogueResult<CatalogueGroup> { .init(values: [], isCached: false) }

    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> {
        try await withCheckedThrowingContinuation { continuation in
            continuations[groupId] = continuation
            if let waiter {
                self.waiter = nil
                waiter.resume(returning: groupId)
            } else {
                calls.append(groupId)
            }
        }
    }

    func nextCall() async -> String {
        if !calls.isEmpty { return calls.removeFirst() }
        return await withCheckedContinuation { waiter = $0 }
    }

    func complete(_ groupId: String, seasons: [HarvestSeason]) {
        continuations.removeValue(forKey: groupId)?.resume(returning: .init(values: seasons, isCached: false))
    }
}
