//
//  CataloguePreloadTests+Discovery.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 14.09.2026.
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
import Combine
import FactoryKit
import DatabaseKit
import GRDB
import Networking
import RestClient
import Targets
import StorageKit
import Utility
@testable import Whimo

extension CataloguePreloadTests {
    func testSelectionDiscoversCommodityWithoutWaitingThenCreatesOfflineAfterRestart() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        await preload.prepareCatalogues()
        AppContainer.shared.appState.register { FilterAppStateTestDouble() }.scope(.unique)
        let commodities = makeCommodities(database: fixture.database, target: target)
        let savedSeasons = makeSeasons(database: fixture.database, target: target)
        AppContainer.shared.seasonCatalogueRepository.register { savedSeasons }.scope(.unique)
        AppContainer.shared.seasonalBalanceRepository.register { PreloadUnusedBalance() }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        AppContainer.shared.commodityCachingRepository.register { commodities }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { preload }.scope(.unique)
        let selection = AppContainer.shared.commodityInteractor.scope(.unique).resolve()
        await target.discoverRice()
        let entered = expectation(description: "New Commodity preparation started")
        await target.pauseRice(entered: entered)
        let groups = try await selection.fetchCommodityGroups()
        XCTAssertEqual(groups.last?.commodities.last?.id, "rice")
        await fulfillment(of: [entered], timeout: 3)
        _ = try await selection.fetchCommodityGroups()
        let pending = await target.seasonRequests
        XCTAssertEqual(pending, ["beans:1", "beans:2", "coffee:1", "empty:1", "rice:1"])
        guard pending.contains("rice:1") else { return }
        await target.resume()
        await preload.prepareCatalogues()
        let completed = await target.seasonRequests
        XCTAssertEqual(completed, pending, "Repeated discovery skips complete and successfully empty snapshots")
        let pages = await target.groupPages
        XCTAssertEqual(pages, [1, 2, 1, 2, 1, 2], "Selection retains online catalogue refresh")

        await target.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let offlineSelection = CommodityInteractorImpl(dataFetcherInteractor: makePreload(database: database, target: target,
            connectivity: CatalogueOfflineConnectivity()),
            commodityRepository: makeCommodities(database: database, target: target),
            seasonRepository: makeSeasons(database: database, target: target), balanceRepository: PreloadUnusedBalance(),
            accountId: { "fixture-buyer" })
        let saved = try await offlineSelection.fetchCommodityGroups()
        let rice = try XCTUnwrap(saved.flatMap(\.commodities).first { $0.id == "rice" })
        XCTAssertEqual(rice.group.id, "coffee-group")
        XCTAssertFalse(saved.flatMap(\.commodities).contains { $0.id == "undiscovered" })
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: database, target: target),
            balances: PreloadUnusedBalance())
        let seasons = try await creation.seasons(commodityId: rice.id)
        XCTAssertTrue(seasons.isCached)
        let season = try XCTUnwrap(seasons.values.first)
        let transactions = try discoveryTransactions(fixture: fixture, creation: creation)
        try await transactions.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
            commodityType: rice, volume: "10", action: .buy,
            recipient: .init(recipientID: "supplier", email: "", phone: ""),
            seasonSelection: .init(commodityId: rice.id, season: season))
        for farmer in [true, false] {
            try await transactions.createProducerTransaction(farmLocation: nil, commodityType: rice,
                volume: "12", isBuyingFromFarmer: farmer, transactionCoordinates: nil, inviteRecipient: nil)
        }
        let queued = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 3)
        XCTAssertEqual(Set(queued.compactMap(\.harvestSeasonId)), ["rice-active"])
        XCTAssertEqual(queued.filter { $0.type == .downstream }.count, 1)
        XCTAssertEqual(Set(queued.filter { $0.type == .producer }.map(\.isBuyingFromFarmer)), [true, false])
    }

    func testDiscoveryDuringInitialPreparationRetainsMissingNewCommodityForRetry() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        let entered = expectation(description: "Initial season pagination pending")
        await target.pauseBeanContinuation(entered: entered)
        let initial = Task { await preload.prepareCatalogues() }
        await fulfillment(of: [entered], timeout: 3)
        await target.discoverRice()
        await target.failSeasons(for: "rice", true)
        let selection = CommodityInteractorImpl(dataFetcherInteractor: preload,
            commodityRepository: makeCommodities(database: fixture.database, target: target),
            seasonRepository: makeSeasons(database: fixture.database, target: target), balanceRepository: PreloadUnusedBalance(),
            accountId: { "fixture-buyer" })
        let groups = try await selection.fetchCommodityGroups()
        XCTAssertTrue(groups.flatMap(\.commodities).contains { $0.id == "rice" })
        await target.resume()
        await initial.value
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "rice:1"],
            "Discovery must retain a pass when initial preparation already captured the old catalogue")

        await target.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let offlineSelection = CommodityInteractorImpl(dataFetcherInteractor: makePreload(database: database, target: target,
            connectivity: CatalogueOfflineConnectivity()), commodityRepository: makeCommodities(database: database, target: target),
            seasonRepository: makeSeasons(database: database, target: target), balanceRepository: PreloadUnusedBalance(),
            accountId: { "fixture-buyer" })
        let saved = try await offlineSelection.fetchCommodityGroups()
        XCTAssertTrue(saved.flatMap(\.commodities).contains { $0.id == "rice" })
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: database, target: target), balances: PreloadUnusedBalance())
        do {
            _ = try await creation.seasons(commodityId: "rice")
            XCTFail("Failed preparation cannot invent offline seasons")
        } catch CreationSeasonError.catalogueRequired { }

        await target.goOnline()
        await target.failSeasons(for: "rice", false)
        await makePreload(database: database, target: target).prepareCatalogues()
        let retried = await target.seasonRequests
        XCTAssertEqual(retried, requests + ["rice:1"], "Recovery after restart requests only the missing snapshot")
        await target.goOffline()
        let recovered = try await creation.seasons(commodityId: "rice")
        XCTAssertEqual(recovered.values.map(\.id), ["rice-active"])
        XCTAssertTrue(recovered.isCached)
    }

    func testCreationRefreshReplacesEmptyAndChangedSeasonsRetainsFailuresAndCapturedQueueIds() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        await preload.prepareCatalogues()
        await target.discoverRice()
        let selection = CommodityInteractorImpl(dataFetcherInteractor: preload,
            commodityRepository: makeCommodities(database: fixture.database, target: target),
            seasonRepository: makeSeasons(database: fixture.database, target: target), balanceRepository: PreloadUnusedBalance(),
            accountId: { "fixture-buyer" })
        let groups = try await selection.fetchCommodityGroups()
        await preload.prepareCatalogues()
        let rice = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "rice" })
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: fixture.database, target: target),
            balances: PreloadUnusedBalance())
        await target.goOffline()
        let transactions = try discoveryTransactions(fixture: fixture, creation: creation)
        try await transactions.createProducerTransaction(farmLocation: nil, commodityType: rice,
            volume: "12", isBuyingFromFarmer: true, transactionCoordinates: nil, inviteRecipient: nil)

        await target.goOnline()
        await target.replaceSeasons(for: "empty", with: [discoverySeason("empty-new", status: .active)])
        await target.replaceSeasons(for: "rice", with: [discoverySeason("rice-active", status: .past),
            discoverySeason("rice-next", status: .active)])
        _ = try await selection.fetchCommodityGroups()
        await preload.prepareCatalogues()
        let afterDiscovery = await target.seasonRequests
        XCTAssertEqual(afterDiscovery.filter { $0 == "empty:1" }.count, 1, "Discovery skips completed empty snapshots")
        XCTAssertEqual(afterDiscovery.filter { $0 == "rice:1" }.count, 1)
        let populated = try await creation.seasons(commodityId: "empty")
        XCTAssertEqual(populated.values.map(\.id), ["empty-new"])
        XCTAssertFalse(populated.isCached)
        let changed = try await creation.seasons(commodityId: "rice")
        XCTAssertEqual(changed.values.map(\.id), ["rice-active", "rice-next"])
        XCTAssertEqual(changed.values.map(\.status), [.past, .active])
        XCTAssertFalse(changed.isCached)
        let afterCreation = await target.seasonRequests
        XCTAssertEqual(afterCreation, afterDiscovery + ["empty:1", "rice:1"])

        await target.failSeasons(for: "rice", true)
        do {
            _ = try await creation.seasons(commodityId: "rice")
            XCTFail("A failed online refresh must retain the existing creation error behavior")
        } catch CreationSeasonError.catalogueRequired { }
        await target.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let restoredCreation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: database, target: target),
            balances: PreloadUnusedBalance())
        let retained = try await restoredCreation.seasons(commodityId: "rice")
        XCTAssertTrue(retained.isCached)
        XCTAssertEqual(retained.values.map(\.id), ["rice-active", "rice-next"])
        XCTAssertEqual(retained.values.map(\.status), [.past, .active])
        let retainedEmpty = try await restoredCreation.seasons(commodityId: "empty")
        XCTAssertEqual(retainedEmpty.values.map(\.id), ["empty-new"])
        let queuedBefore = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(queuedBefore.map(\.harvestSeasonId), ["rice-active"])
        let restoredTransactions = try discoveryTransactions(fixture: fixture, creation: restoredCreation)
        try await restoredTransactions.createProducerTransaction(farmLocation: nil, commodityType: rice,
            volume: "12", isBuyingFromFarmer: false, transactionCoordinates: nil, inviteRecipient: nil)
        let queuedAfter = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(Set(queuedAfter.compactMap(\.harvestSeasonId)), ["rice-active", "rice-next"])
        let original = try XCTUnwrap(queuedAfter.first { $0.id == queuedBefore.first?.id })
        XCTAssertEqual(original.harvestSeasonId, "rice-active")
    }

    private func discoverySeason(_ identifier: String, status: ResponseModels.HarvestSeason.Status) -> ResponseModels.HarvestSeason {
        .init(id: identifier, name: identifier, startDate: "2025-09-01", endDate: "2026-09-01", status: status)
    }

    private func discoveryTransactions(fixture: BuyerPersistenceFixture,
                                       creation: CreationSeasonInteractor) throws -> TransactionsInteractorImpl {
        let local = try fixture.reopenedLocal()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: BuyerTransactionTarget(), transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: [])
        return TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local, creationSeasonInteractor: creation)
    }
}
