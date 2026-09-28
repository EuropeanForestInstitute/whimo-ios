//
//  CataloguePreloadTests+Integrated.swift
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
import FactoryKit
import DatabaseKit
import GRDB
import Networking
import RestClient
import Targets
import StorageKit
import Utility
import Resources
@testable import Whimo

extension CataloguePreloadTests {
    func testCommoditySelectionReusesSavedActiveBalanceAfterRestart() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let balanceTarget = BalanceTargetDouble()
        let state = FilterAppStateTestDouble()
        let balances = makeIntegratedBalances(database: fixture.database, target: balanceTarget)
        let list = BalanceListInteractorImpl(appState: state, repository: balances)
        let preload = makePreload(database: fixture.database, target: target, balanceInteractor: list)
        try await balanceTarget.returnBalance(volume: 10, commodityId: "beans", seasonId: "beans-active", status: "active")
        await preload.fetchRemoteData()
        await preload.prepareCatalogues()
        await target.goOffline()
        await balanceTarget.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let offlinePreload = makePreload(database: database, target: target, connectivity: CatalogueOfflineConnectivity())
        let commodities = makeCommodities(database: database, target: target)
        let seasons = makeSeasons(database: database, target: target)
        let savedBalances = makeIntegratedBalances(database: database, target: balanceTarget)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { offlinePreload }.scope(.unique)
        AppContainer.shared.commodityCachingRepository.register { commodities }.scope(.unique)
        AppContainer.shared.seasonCatalogueRepository.register { seasons }.scope(.unique)
        AppContainer.shared.seasonalBalanceRepository.register { savedBalances }.scope(.unique)
        let active = try await seasons.seasons(commodityId: "beans").values.first { $0.status == .active }
        XCTAssertEqual(active?.id, "beans-active")
        let before = try await savedBalances.cachedExact(commodityId: "beans", seasonId: "beans-active")
        XCTAssertEqual(before.volume, 10)
        let groups = try await AppContainer.shared.commodityInteractor.resolve().fetchCommodityGroups()
        let after = try await savedBalances.cachedExact(commodityId: "beans", seasonId: "beans-active")
        XCTAssertEqual(after.volume, 10)
        let beans = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "beans" })
        XCTAssertEqual(beans.balance, 10)
        XCTAssertNil(groups.flatMap(\.commodities).first { $0.id == "coffee" }?.balance)
        let coffee = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "coffee" })
        XCTAssertEqual(CommoditiesListModule.RowListItem(item: coffee, selectedItem: .constant(nil)).balanceText,
            AppLocale.CreationSeason.balanceUnavailable)
        try await balanceTarget.returnBalance(volume: 99, commodityId: "beans", seasonId: "beans-past", status: "past")
        _ = try await balances.page(query: .init(), page: 1, cacheOnly: false)
        let afterPast = try await AppContainer.shared.commodityInteractor.resolve().fetchCommodityGroups()
        XCTAssertEqual(afterPast.flatMap(\.commodities).first { $0.id == "beans" }?.balance, 10)
        try await balanceTarget.returnBalance(volume: 0, commodityId: "beans", seasonId: "beans-active", status: "active")
        _ = try await balances.page(query: .init(), page: 1, cacheOnly: false)
        await balanceTarget.goOffline()
        let afterZero = try await AppContainer.shared.commodityInteractor.resolve().fetchCommodityGroups()
        let zeroBeans = try XCTUnwrap(afterZero.flatMap(\.commodities).first { $0.id == "beans" })
        XCTAssertEqual(zeroBeans.balance, 0)
        XCTAssertNotEqual(CommoditiesListModule.RowListItem(item: zeroBeans, selectedItem: .constant(nil)).balanceText,
            AppLocale.CreationSeason.balanceUnavailable)
    }

    func testUnknownBalanceSalesInEverySeasonSurviveOfflineRestart() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        await makePreload(database: fixture.database, target: target).prepareCatalogues()
        await target.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let balanceTarget = BalanceTargetDouble()
        await balanceTarget.goOffline()
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: database, target: target),
            balances: makeIntegratedBalances(database: database, target: balanceTarget))
        let state = FilterAppStateTestDouble()
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register { creation }.scope(.unique)
        let transactions = try makeIntegratedTransactions(fixture: fixture, target: BuyerTransactionTarget(), state: state, creation: creation)
        let volume = CommodityVolumeModule.ViewModel(volumeAmount: "12", commodityType: BuyerVolumeTests.commodity,
            transactionType: .downstream(action: .sell, recipient: .empty))
        await volume.loadSeasons()
        for season in volume.seasons {
            volume.selectSeason(season)
            await volume.loadBalance()
            XCTAssertTrue(volume.balanceUnavailable)
            XCTAssertTrue(volume.canConfirm)
            XCTAssertFalse(volume.enableNoteBanner)
            volume.didTapConfirm()
            XCTAssertNil(state.createTransaction.value.confirmedBalance)
            try await transactions.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
                commodityType: BuyerVolumeTests.commodity, volume: state.createTransaction.value.volumeAmount, action: .sell,
                recipient: .init(recipientID: "recipient", email: "", phone: ""),
                seasonSelection: state.createTransaction.value.seasonSelection)
        }
        let queued = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 3)
        XCTAssertEqual(Set(queued.compactMap(\.harvestSeasonId)), ["beans-active", "beans-past", "beans-archive"])
        XCTAssertTrue(queued.allSatisfy { $0.volume == 12 && $0.action == .sell })
    }

    func testActiveListBalanceIsAvailableOnFirstOfflineVolumeEntryAndRepeatedReopening() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let state = FilterAppStateTestDouble()
        let catalogueTarget = PreloadCatalogueTarget()
        let balanceTarget = BalanceTargetDouble()
        try await balanceTarget.returnBalance(volume: 10, commodityId: "beans", seasonId: "beans-active", status: "active", partial: true)
        let list = BalanceListInteractorImpl(appState: state,
            repository: makeIntegratedBalances(database: fixture.database, target: balanceTarget))
        let preload = makePreload(database: fixture.database, target: catalogueTarget, balanceInteractor: list)
        await preload.fetchRemoteData()
        await preload.prepareCatalogues()
        XCTAssertEqual(state.balance.value.list.value?.first?.volume, 10)
        XCTAssertEqual(state.balance.value.list.value?.first?.season?.id, "beans-active")
        XCTAssertEqual(state.balance.value.pagination?.nextPage, 2)

        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "active-offline-" + UUID().uuidString))
        defer { defaults.clear() }
        let client = RestClient(baseURL: try XCTUnwrap(URL(string: "https://catalogue.invalid")),
            connectivity: CatalogueOfflineConnectivity(), userDefaults: defaults)
        AppContainer.shared.appState.register { state }.scope(.unique)
        state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
        for _ in 0..<3 {
            let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
            let catalogue = SeasonCatalogueRepositoryImpl(groupsTarget: catalogueTarget,
                seasonsTarget: RestHarvestSeasonsTarget(restClient: client), database: database,
                mapper: SeasonCatalogueMapper(), accountId: { "fixture-buyer" })
            let balances = SeasonalBalanceRepositoryImpl(target: RestBalancesTarget(restClient: client), database: database,
                mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture-buyer" })
            let creation = CreationSeasonInteractorImpl(catalogue: catalogue, balances: balances)
            AppContainer.shared.creationSeasonInteractor.register { creation }.scope(.unique)
            let volume = CommodityVolumeModule.ViewModel(volumeAmount: "10", commodityType: BuyerVolumeTests.commodity,
                transactionType: .downstream(action: .sell, recipient: .empty))
            await volume.loadSeasons()
            XCTAssertEqual(volume.selectedSeason?.id, "beans-active", "First entry defaults to the saved Active season")
            for _ in 0..<2 {
                await volume.loadBalance()
                XCTAssertEqual(volume.seasonalBalance?.volume, 10)
                XCTAssertEqual(volume.seasonalBalance?.isCached, true)
                XCTAssertFalse(volume.balanceUnavailable)
                XCTAssertTrue(volume.canConfirm)
            }
            volume.volumeText = "11"
            XCTAssertTrue(volume.enableNoteBanner)
            XCTAssertTrue(volume.canConfirm, "Known Active shortage remains allowed offline")
        }
    }

    func testAuthorizedPreparationToOfflineMixedCreationRestartAndReachabilityUpload() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let catalogueTarget = PreloadCatalogueTarget()
        let balanceTarget = BalanceTargetDouble()
        try await balanceTarget.returnBalance(volume: 2, commodityId: "beans", seasonId: "beans-past", partial: true)
        let state = FilterAppStateTestDouble()
        let balance = makeIntegratedBalances(database: fixture.database, target: balanceTarget)
        let list = BalanceListInteractorImpl(appState: state, repository: balance)
        let connectivity = PreloadMutableConnectivity()
        let preload = makePreload(database: fixture.database, target: catalogueTarget,
            connectivity: connectivity, balanceInteractor: list)
        let cataloguePending = expectation(description: "Initial catalogue transport suspended")
        await catalogueTarget.pauseFirstPage(entered: cataloguePending)
        let remoteFinished = expectation(description: "Normal remote preload and Balance list completed")
        let observer = IntegratedPreloadObserver(preload: preload, finished: remoteFinished)
        var root: RootModule.ViewModel? = makeRoot(preload: observer, connectivity: connectivity, state: state)
        await fulfillment(of: [cataloguePending, remoteFinished], timeout: 3)
        XCTAssertEqual(state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(root?.isLoading, false)
        XCTAssertEqual(state.balance.value.list.value?.first?.volume, 2)
        XCTAssertEqual(state.balance.value.pagination?.nextPage, 2)
        await catalogueTarget.resume()
        await preload.prepareCatalogues()
        await catalogueTarget.goOffline()
        await balanceTarget.goOffline()
        connectivity.send(.notReachable)
        root = nil

        // Recreate cache, creation and transaction dependencies against the same file, without cache seeding.
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let commodities = try await makeCommodities(database: database, target: catalogueTarget).fetchCommodityGroups()
        let beans = try XCTUnwrap(commodities.flatMap(\.commodities).first { $0.id == "beans" })
        let coffee = try XCTUnwrap(commodities.flatMap(\.commodities).first { $0.id == "coffee" })
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: database, target: catalogueTarget),
            balances: makeIntegratedBalances(database: database, target: balanceTarget))
        let target = BuyerTransactionTarget(mixedQueue: true)
        let offlineState = FilterAppStateTestDouble()
        offlineState.transactions[\.list] = .loaded(value: [])
        let transactions = try makeIntegratedTransactions(fixture: fixture, target: target, state: offlineState, creation: creation)
        try await createPreparedQueue(transactions: transactions, creation: creation, beans: beans, coffee: coffee)
        let queued = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 4)
        XCTAssertEqual(Set(queued.compactMap(\.harvestSeasonId)), ["beans-archive", "beans-past", "beans-active", "coffee-active"])
        XCTAssertEqual(queued.filter { $0.type == .producer }.count, 2)
        XCTAssertEqual(Set(queued.filter { $0.type == .producer }.map(\.isBuyingFromFarmer)), [true, false])
        XCTAssertEqual(queued.first { $0.action == .sell }?.harvestSeasonId, "beans-past")
        XCTAssertEqual(queued.first { $0.action == .sell }?.buyer?.username, "recipient-2")
        XCTAssertEqual(queued.first { $0.type == .downstream && $0.action == .buy }?.seller?.username, "recipient-1")
        try assertIntegratedEvidence(queued)
        try await verifyPreparedQueueRecovery(fixture: fixture, target: target, catalogueTarget: catalogueTarget, queued: queued)
    }
}

extension CataloguePreloadTests {
    func makeIntegratedBalances(database: DatabaseKit.Database, target: BalanceTargetDouble) -> SeasonalBalanceRepositoryImpl {
        SeasonalBalanceRepositoryImpl(target: target, database: database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture-buyer" })
    }

    func makeIntegratedTransactions(fixture: BuyerPersistenceFixture, target: BuyerTransactionTarget,
                                    state: FilterAppStateTestDouble, creation: CreationSeasonInteractor) throws -> TransactionsInteractorImpl {
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let local = try fixture.reopenedLocal()
        return TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local, creationSeasonInteractor: creation)
    }

    func createPreparedQueue(transactions: TransactionsInteractor, creation: CreationSeasonInteractor,
                             beans: CommodityGroupModel.Commodity, coffee: CommodityGroupModel.Commodity) async throws {
        let seasons = try await creation.seasons(commodityId: beans.id)
        for index in 1...4 {
            let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".geojson")
            let evidence = Data("prepared-evidence-\(index)".utf8)
            try evidence.write(to: source)
            defer { try? FileManager.default.removeItem(at: source) }
            let file = FileObject(id: "evidence-\(index).geojson", url: source, creationDate: .now,
                fileType: .typeRegular, size: NSNumber(value: evidence.count), childs: [])
            let location = FarmLocation.fileManager(file: file, coordinates: .init(latitude: 0, longitude: 0))
            if index <= 2 {
                let seasonId = index == 1 ? "beans-archive" : "beans-past"
                let season = try XCTUnwrap(seasons.values.first { $0.id == seasonId })
                try await transactions.createDownstreamTransaction(farmLocation: location, transactionCoordinates: nil,
                    commodityType: beans, volume: "\(index)", action: index == 1 ? .buy : .sell,
                    recipient: .init(recipientID: "recipient-\(index)", email: "", phone: ""),
                    seasonSelection: .init(commodityId: beans.id, season: season))
            } else {
                try await transactions.createProducerTransaction(farmLocation: location, commodityType: index == 3 ? beans : coffee,
                    volume: "\(index)", isBuyingFromFarmer: index == 3, transactionCoordinates: nil,
                    inviteRecipient: .init(recipientID: "", email: "producer-\(index)@example.invalid", phone: ""))
            }
            try FileManager.default.removeItem(at: source)
        }
    }

    func assertIntegratedEvidence(_ rows: IdentifiedArrayOf<TransactionModel>) throws {
        for row in rows {
            let file = try XCTUnwrap(row.persistingData.farmLocationFile)
            XCTAssertEqual(file.fileName, "evidence-\(Int(row.volume)).geojson")
            XCTAssertEqual(try Data(contentsOf: file.fileURL), Data("prepared-evidence-\(Int(row.volume))".utf8))
        }
    }

    func verifyPreparedQueueRecovery(fixture: BuyerPersistenceFixture, target: BuyerTransactionTarget,
                                     catalogueTarget: PreloadCatalogueTarget, queued: IdentifiedArrayOf<TransactionModel>) async throws {
        let local = try fixture.reopenedLocal()
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: queued)
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: local,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        do {
            try await sync.syncTransactions()
            XCTFail("Disabled transport must retain the entire queue")
        } catch RestClient.RestError.connectionLost { }
        let failed = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(Set(failed.map(\.id)), Set(queued.map(\.id)))
        try assertIntegratedEvidence(failed)

        // Root's actual reachability subscription drives a recreated production sync actor.
        let connectivity = PreloadMutableConnectivity()
        connectivity.send(.notReachable)
        let restarted = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: try fixture.reopenedLocal(),
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        let uploadObserver = IntegratedSyncObserver(sync: restarted)
        let preload = makePreload(database: try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath)),
            target: catalogueTarget, connectivity: connectivity)
        let entered = expectation(description: "Offline restarted Root entered")
        let root = makeRoot(preload: IntegratedPreloadObserver(preload: preload, finished: entered),
            connectivity: connectivity, state: state, sync: uploadObserver)
        await fulfillment(of: [entered], timeout: 3)
        await target.goOnline()
        await catalogueTarget.goOnline()
        await catalogueTarget.replaceSeasons(for: "beans", with: [
            .init(id: "beans-active", name: "Captured season now Past", startDate: "2025-09-01", endDate: "2026-09-01", status: .past)
        ])
        _ = try await makeSeasons(database: fixture.database, target: catalogueTarget).seasons(commodityId: "beans")
        let partial = expectation(description: "Reachability upload stops after one success")
        await uploadObserver.observe(partial)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [partial], timeout: 3)
        let didFail = await uploadObserver.failed
        XCTAssertTrue(didFail)
        let remaining = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(remaining.count, 3)
        try assertIntegratedEvidence(remaining)
        let attempts = await target.mixedAttempts
        let successful = try XCTUnwrap(attempts.first)
        let completed = expectation(description: "Second reconnect uploads remaining queue")
        await uploadObserver.observe(completed)
        connectivity.send(.notReachable)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [completed], timeout: 3)
        let finalFailure = await uploadObserver.failed
        XCTAssertFalse(finalFailure)
        try await restarted.syncTransactions()
        let finalAttempts = await target.mixedAttempts
        XCTAssertEqual(finalAttempts.count, 5)
        XCTAssertEqual(finalAttempts.filter { $0 == successful }.count, 1)
        let pending = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(pending.isEmpty)
        let evidence = await target.mixedEvidence
        for original in queued {
            let season = try XCTUnwrap(original.harvestSeasonId)
            let uploaded = try await local.fetchTransaction(by: "remote-" + season)
            XCTAssertEqual(uploaded.harvestSeasonId, season)
            XCTAssertEqual(uploaded.commodity.id, original.commodity.id)
            XCTAssertEqual(uploaded.volume, original.volume)
            XCTAssertEqual(uploaded.harvestSeason?.status, .past)
            XCTAssertEqual(evidence[season], Data("prepared-evidence-\(Int(original.volume))".utf8))
        }
        let downstream = await target.requests
        for request in downstream {
            let buying = request.transactionData.action == .buy
            XCTAssertEqual(request.transactionData.harvestSeasonId, buying ? "beans-archive" : "beans-past")
            XCTAssertEqual(request.transactionData.recipient.name, buying ? "recipient-1" : "recipient-2")
            XCTAssertEqual(Double(request.transactionData.volume), buying ? 1 : 2)
        }
        let producers = await target.producerRequests
        for request in producers {
            let farmer = request.transactionData.isBuyingFromFarmer
            XCTAssertEqual(request.transactionData.harvestSeasonId, farmer ? "beans-active" : "coffee-active")
            XCTAssertEqual(request.transactionData.recipient?.email, farmer ? "producer-3@example.invalid" : "producer-4@example.invalid")
            XCTAssertEqual(Double(request.transactionData.volume), farmer ? 3 : 4)
        }
        XCTAssertTrue(state.transactions.value.updatingList.isEmpty)
        await preload.prepareCatalogues()
        withExtendedLifetime(root) { }
    }
}

// Completion signals wrap public operations without replacing production preload or upload work.
private actor IntegratedPreloadObserver: DataFetcherInteractor {
    let preload: DataFetcherInteractorImpl
    let finished: XCTestExpectation
    init(preload: DataFetcherInteractorImpl, finished: XCTestExpectation) { self.preload = preload; self.finished = finished }
    func loadCacheData() async { await preload.loadCacheData() }
    func fetchRemoteData() async { await preload.fetchRemoteData(); finished.fulfill() }
    func prepareCatalogues() async { await preload.prepareCatalogues() }
    func startCataloguePreparation() async { await preload.startCataloguePreparation() }
    func cancelCataloguePreparation() async { await preload.cancelCataloguePreparation() }
}

private actor IntegratedSyncObserver: OfflineTransactionsSyncInteractor {
    func discardPendingResults() async { await sync.discardPendingResults() }
    let sync: OfflineTransactionsSyncInteractor
    private var completion: XCTestExpectation?
    var failed = false
    init(sync: OfflineTransactionsSyncInteractor) { self.sync = sync }
    func observe(_ expectation: XCTestExpectation) { completion = expectation }
    func syncTransactions() async throws {
        failed = false
        do { try await sync.syncTransactions() } catch { failed = true }
        completion?.fulfill()
        completion = nil
    }
}
