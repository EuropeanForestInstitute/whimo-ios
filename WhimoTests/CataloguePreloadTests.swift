//
//  CataloguePreloadTests.swift
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

@MainActor
final class CataloguePreloadTests: XCTestCase {
    func testPreloadReturnsWhileCatalogueIsPendingThenReopensForBuyerAndBothProducerSources() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Catalogue requested")
        await target.pauseFirstPage(entered: entered)
        let preload = makePreload(database: fixture.database, target: target)
        await preload.fetchRemoteData()
        await fulfillment(of: [entered], timeout: 3)
        await preload.fetchRemoteData()
        let pendingRequests = await target.groupPages
        XCTAssertEqual(pendingRequests, [1], "Overlapping initial triggers share preparation")
        await target.resume()
        await preload.prepareCatalogues()
        await preload.prepareCatalogues()
        let reopenedOnline = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        await makePreload(database: reopenedOnline, target: target).prepareCatalogues()
        let groupPages = await target.groupPages
        let seasonRequests = await target.seasonRequests
        XCTAssertEqual(groupPages, [1, 2])
        XCTAssertEqual(seasonRequests, ["beans:1", "beans:2", "coffee:1", "empty:1"])

        await target.goOffline()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let commodities = makeCommodities(database: database, target: target)
        let groups = try await commodities.fetchCommodityGroups()
        XCTAssertEqual(Set(groups.map(\.id)), ["cocoa", "coffee-group"])
        let selectable = groups.flatMap(\.commodities)
        XCTAssertEqual(Set(selectable.map(\.id)), ["beans", "coffee", "empty"])
        let catalogue = makeSeasons(database: database, target: target)
        let creation = CreationSeasonInteractorImpl(catalogue: catalogue, balances: PreloadUnusedBalance())
        let transactionTarget = BuyerTransactionTarget()
        let local = try fixture.reopenedLocal()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: transactionTarget, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: [])
        let transactions = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local, creationSeasonInteractor: creation)
        let beans = try XCTUnwrap(selectable.first { $0.id == "beans" })
        let seasons = try await creation.seasons(commodityId: beans.id)
        XCTAssertEqual(seasons.values.map(\.status), [.active, .past, .archive])
        let archived = try XCTUnwrap(seasons.values.last)
        try await transactions.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
            commodityType: beans, volume: "10", action: .buy,
            recipient: .init(recipientID: "supplier", email: "", phone: ""),
            seasonSelection: .init(commodityId: beans.id, season: archived))
        let coffee = try XCTUnwrap(selectable.first { $0.id == "coffee" })
        for farmer in [true, false] {
            try await transactions.createProducerTransaction(farmLocation: nil, commodityType: coffee,
                volume: "12", isBuyingFromFarmer: farmer, transactionCoordinates: nil,
                inviteRecipient: farmer ? nil : .init(recipientID: "", email: "cooperative@example.invalid", phone: ""))
        }
        let reopened = try fixture.reopenedLocal()
        let queued = try await reopened.fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 3)
        XCTAssertEqual(queued.filter { $0.type == .downstream }.map(\.harvestSeasonId), ["beans-archive"])
        XCTAssertEqual(queued.filter { $0.type == .producer }.map(\.harvestSeasonId), ["coffee-active", "coffee-active"])
        XCTAssertEqual(Set(queued.filter { $0.type == .producer }.map(\.isBuyingFromFarmer)), [true, false])
    }

    func testIncompleteCommodityResponseIsNotRecordedAsPrepared() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        await target.truncateGroups(true)
        let preload = makePreload(database: database, target: target)
        await preload.prepareCatalogues()
        await target.truncateGroups(false)
        await preload.prepareCatalogues()
        let pages = await target.groupPages
        XCTAssertEqual(pages, [1, 1, 2], "Incomplete pagination must remain retryable")
        await target.goOffline()
        let groups = try await makeCommodities(database: database, target: target).fetchCommodityGroups()
        XCTAssertEqual(Set(groups.flatMap(\.commodities).map(\.id)), ["beans", "coffee", "empty"])
    }

    func testLaterSeasonFailureRetainsOtherCommoditiesAndRetriesOnlyMissingSnapshot() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        await target.failBeanContinuation(true)
        let preload = makePreload(database: database, target: target)
        await preload.prepareCatalogues()
        await target.goOffline()
        let catalogue = makeSeasons(database: database, target: target)
        let coffee = try await catalogue.seasons(commodityId: "coffee")
        XCTAssertEqual(coffee.values.map(\.id), ["coffee-active"])
        let empty = try await catalogue.seasons(commodityId: "empty")
        XCTAssertTrue(empty.isCached)
        XCTAssertTrue(empty.values.isEmpty)
        do {
            _ = try await catalogue.seasons(commodityId: "beans")
            XCTFail("A successful first page is not a complete season snapshot")
        } catch RestClient.RestError.connectionLost { }
        let creation = CreationSeasonInteractorImpl(catalogue: catalogue, balances: PreloadUnusedBalance())
        for commodity in ["empty", "missing", "beans"] {
            do {
                _ = try await creation.seasons(commodityId: commodity)
                XCTFail("Missing or empty required seasons must require a connection")
            } catch CreationSeasonError.catalogueRequired { }
        }
        await target.goOnline()
        await target.failBeanContinuation(false)
        await preload.prepareCatalogues()
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "beans:1", "beans:2"])
    }

    func testFailedOnlineRefreshKeepsPreparedSeasonSnapshot() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: database, target: target)
        await preload.prepareCatalogues()
        let catalogue = makeSeasons(database: database, target: target)
        await target.failBeanContinuation(true)
        do {
            _ = try await catalogue.seasons(commodityId: "beans")
            XCTFail("A failed refresh must report its failure")
        } catch is CocoaError { }
        await target.goOffline()
        let retained = try await catalogue.seasons(commodityId: "beans")
        XCTAssertEqual(retained.values.map(\.id), ["beans-active", "beans-past", "beans-archive"])
        XCTAssertTrue(retained.isCached)
    }

    func testCancelledPreloadCannotWriteAfterAccountCleanupEvenWhenTransportIgnoresCancellation() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Old account request pending")
        await target.pauseFirstPage(entered: entered)
        let account: () -> String? = { (fixture.storage.get(.user) as UserModel?)?.id }
        let preload = makePreload(database: fixture.database, target: target, accountId: account)
        let pending = Task { await preload.prepareCatalogues() }
        await fulfillment(of: [entered], timeout: 3)
        await preload.cancelCataloguePreparation()
        fixture.storage.set(UserModel(id: "new-account", username: "Fixture", gadgets: []), key: .user)
        try await fixture.database.flush()
        await target.resume()
        await pending.value
        await target.goOffline()
        await preload.prepareCatalogues()
        let groups = try await makeCommodities(database: fixture.database, target: target, accountId: account).fetchCommodityGroups()
        XCTAssertTrue(groups.isEmpty)
        let catalogue = makeSeasons(database: fixture.database, target: target, accountId: account)
        do {
            _ = try await catalogue.seasons(commodityId: "beans")
            XCTFail("Obsolete preparation must not repopulate the cleared database")
        } catch RestClient.RestError.connectionLost { }
    }

    func testAuthorizedRootPresentsMainScreenWhileCatalogueTransportIsPending() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Authorized root starts catalogue preparation")
        await target.pauseFirstPage(entered: entered)
        let preload = makePreload(database: database, target: target)
        let state = FilterAppStateTestDouble()
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "preload-root-" + UUID().uuidString))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { preload }.scope(.unique)
        AppContainer.shared.userDefaultsStore.register { defaults }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.connectivity.register { CatalogueOfflineConnectivity() }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { PreloadUnusedCleaner() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { PreloadUnusedSync() }.scope(.unique)
        let root = RootModule.ViewModel()
        await fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertFalse(root.isLoading)
        XCTAssertFalse(state.system.value.isLoading)
        await target.resume()
        await preload.prepareCatalogues()
        withExtendedLifetime(root) { }
    }

    func testFailedCatalogueCommitRollsBackCommoditiesAndCompletionTogether() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        try await database.save { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_preparation BEFORE INSERT ON seasonCatalogueCache
                WHEN NEW.id = 'selection:commodities'
                BEGIN SELECT RAISE(ABORT, 'injected catalogue failure'); END;
                """)
        }
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: database, target: target)
        await preload.prepareCatalogues()
        await target.goOffline()
        let groups = try await makeCommodities(database: database, target: target).fetchCommodityGroups()
        XCTAssertTrue(groups.isEmpty, "A failed commit must not expose a partial selection catalogue")
        try await database.save { db in try db.execute(sql: "DROP TRIGGER fail_preparation") }
        await target.goOnline()
        await preload.prepareCatalogues()
        let pages = await target.groupPages
        XCTAssertEqual(pages, [1, 2, 1, 2])
    }

    func testOldAccountSeasonResponseCannotRepopulateCacheWithoutCallerCancellation() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Old account season continuation pending")
        await target.pauseBeanContinuation(entered: entered)
        let account: () -> String? = { (fixture.storage.get(.user) as UserModel?)?.id }
        let catalogue = makeSeasons(database: fixture.database, target: target, accountId: account)
        let pending = Task { try await catalogue.seasons(commodityId: "beans") }
        await fulfillment(of: [entered], timeout: 3)
        fixture.storage.set(UserModel(id: "new-account", username: "Fixture", gadgets: []), key: .user)
        try await fixture.database.flush()
        await target.resume()
        do {
            _ = try await pending.value
            XCTFail("An old account response must be discarded even if the caller stays alive")
        } catch is CancellationError { }
        await target.goOffline()
        do {
            _ = try await catalogue.seasons(commodityId: "beans")
            XCTFail("Another account must not receive the old season snapshot")
        } catch RestClient.RestError.connectionLost { }
    }

    func testTruncatedSeasonPaginationNeverBecomesAnOfflineSnapshot() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        await target.truncateSeasons(true)
        await makePreload(database: database, target: target).prepareCatalogues()
        await target.goOffline()
        let catalogue = makeSeasons(database: database, target: target)
        do {
            _ = try await catalogue.seasons(commodityId: "beans")
            XCTFail("Declared missing rows cannot become complete offline coverage")
        } catch RestClient.RestError.connectionLost { }
        let coffee = try await catalogue.seasons(commodityId: "coffee")
        XCTAssertEqual(coffee.values.map(\.id), ["coffee-active"])
    }

    func testAccountSwitchWhileQueueWriteIsPendingCannotRestoreOldParticipantOrTransactions() async throws {
        for producer in [false, true] {
            let fixture = try BuyerPersistenceFixture()
            defer { fixture.storage.clear() }
            let target = PreloadCatalogueTarget()
            let account: () -> String? = { (fixture.storage.get(.user) as UserModel?)?.id }
            await makePreload(database: fixture.database, target: target, accountId: account).prepareCatalogues()
            let seasons = try await makeSeasons(database: fixture.database, target: target, accountId: account).seasons(commodityId: "beans")
            let season = try XCTUnwrap(seasons.values.first)
            let entered = expectation(description: "Queue write pending")
            let gate = PreloadWriteGate(entered: entered)
            let paused = PreloadPausedDatabase(database: fixture.database, gate: gate)
            let local = TransactionsLocalRepositoryImpl(database: paused, commoditiesGroupsMapper: CommoditiesGroupsMapper(),
                transactionsMapper: fixture.mapper, transactionsOfflineMapper: TransactionsOfflineMapper(), userMapper: UserMapper(),
                userOfflineMapper: UserOfflineMapper(), keychainStore: fixture.storage,
                fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")))
            let pending = Task {
                if producer {
                    return try await local.saveProducerTransaction(commodityId: "beans", location: nil, uploadFile: nil,
                        farmCoordinates: nil, transactionCoordinates: nil, volume: "10", inviteRecipient: nil,
                        isBuyingFromFarmer: true, season: season)
                }
                return try await local.saveDownstreamTransaction(commodityId: "beans", volume: "10", location: nil,
                    uploadFile: nil, farmCoordinates: nil, transactionCoordinates: nil, action: .buy,
                    recipient: .name("fixture-supplier"), season: season)
            }
            await fulfillment(of: [entered], timeout: 3)
            fixture.storage.set(UserModel(id: "new-account", username: "Fixture", gadgets: []), key: .user)
            try await fixture.database.flush()
            await makePreload(database: fixture.database, target: target, accountId: account).prepareCatalogues()
            await gate.release()
            do {
                _ = try await pending.value
                XCTFail("Old-account creation must not survive account cleanup")
            } catch { }
            let queued = try await fixture.local().fetchOnDiskTransactions()
            XCTAssertTrue(queued.isEmpty)
            let oldParticipant = try await fixture.database.readOne(DatabaseKit.User.filter(key: "fixture-buyer"))
            XCTAssertNil(oldParticipant)
        }
    }

    func makeCommodities(database: DatabaseKit.Database, target: PreloadCatalogueTarget,
                         accountId: @escaping () -> String? = { "fixture-buyer" }) -> CommodityCachingRepositoryImpl {
        CommodityCachingRepositoryImpl(
            localRepo: CommodityLocalRepositoryImpl(database: database, commoditiesGroupsMapper: CommoditiesGroupsMapper()),
            remoteRepo: CommodityRemoteRepositoryImpl(commoditiesTarget: target, commoditiesGroupsMapper: CommoditiesGroupsMapper()),
            accountId: accountId)
    }

    func makeSeasons(database: DatabaseKit.Database, target: PreloadCatalogueTarget,
                         accountId: @escaping () -> String? = { "fixture-buyer" }) -> SeasonCatalogueRepositoryImpl {
        SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target, database: database,
            mapper: SeasonCatalogueMapper(), accountId: accountId)
    }

    func makePreload(database: DatabaseKit.Database, target: PreloadCatalogueTarget,
                         accountId: @escaping () -> String? = { "fixture-buyer" },
                         connectivity: any Connectivity = PreloadConnectivity(),
                         balanceInteractor: BalanceListInteractor = PreloadBalanceData(),
                         profileInteractor: ProfileInteractor? = nil) -> DataFetcherInteractorImpl {
        let unused = PreloadUnrelatedData()
        return DataFetcherInteractorImpl(profileInteractor: profileInteractor ?? unused, notificationsSettingsInteractor: unused,
            transactionsInteractor: unused, balanceInteractor: balanceInteractor, notificationsInteractor: unused,
            connectivity: connectivity, commodityRepository: makeCommodities(database: database, target: target, accountId: accountId),
            seasonRepository: makeSeasons(database: database, target: target, accountId: accountId), accountId: accountId)
    }
}

actor PreloadCatalogueTarget: CommoditiesTarget, HarvestSeasonsTarget {
    var groupPages: [Int] = []
    var seasonRequests: [String] = []
    private var offline = false
    private var failingCommodities: Set<String> = []
    private var replacements: [String: [ResponseModels.HarvestSeason]] = [:]
    func failSeasons(for commodity: String, _ value: Bool) {
        if value { failingCommodities.insert(commodity) } else { failingCommodities.remove(commodity) }
    }
    func replaceSeasons(for commodity: String, with values: [ResponseModels.HarvestSeason]) { replacements[commodity] = values }
    private var discoversRice = false
    private var riceEntered: XCTestExpectation?
    func discoverRice() { discoversRice = true }
    func pauseRice(entered: XCTestExpectation) { riceEntered = entered }
    private var truncatedGroups = false
    private var failingBeanContinuation = false
    private var seasonEntered: XCTestExpectation?
    private var truncatedSeasons = false
    private var seasonName: String?
    func setSeasonName(_ value: String) { seasonName = value }
    func truncateSeasons(_ value: Bool) { truncatedSeasons = value }
    func pauseBeanContinuation(entered: XCTestExpectation) { seasonEntered = entered }
    func failBeanContinuation(_ value: Bool) { failingBeanContinuation = value }
    func goOnline() { offline = false }
    func truncateGroups(_ value: Bool) { truncatedGroups = value }
    private var entered: XCTestExpectation?
    private var hasPausedGroupFailure = false
    private var continuation: CheckedContinuation<Void, Never>?

    func pauseFirstPage(entered: XCTestExpectation, failOnResume: Bool = false) {
        self.entered = entered
        hasPausedGroupFailure = failOnResume
    }
    func resume() { continuation?.resume(); continuation = nil }
    func goOffline() { offline = true }

    func commodityGroupsList(_ request: RequestModels.CommodityGroupsList) async throws -> ResponseModels.CommodityGroupInfo {
        if offline { throw RestClient.RestError.connectionLost }
        let page = request.pageData.page
        groupPages.append(page)
        if let entered, page == 1 {
            self.entered = nil
            let shouldFail = hasPausedGroupFailure
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                entered.fulfill()
            }
            if shouldFail { throw RestClient.RestError.connectionLost }
        }
        let group = page == 1 ? "cocoa" : "coffee-group"
        let ids = page == 1 ? ["beans"] : ["coffee", "empty"] + (discoversRice ? ["rice"] : [])
        return .init(data: [.init(id: group, name: group, commodities: ids.map {
            .init(id: $0, code: $0, name: $0, unit: "kg", balance: nil,
                  group: .init(id: group, name: group), hasRecipe: false)
        })], pagination: .init(pageSize: 1, nextPage: page == 1 && !truncatedGroups ? 2 : nil, previousPage: page == 2 ? 1 : nil,
                               count: 2, totalPages: 2, page: page))
    }

    func seasons(_ request: RequestModels.HarvestSeasonsList) async throws -> ResponseModels.HarvestSeasonsInfo {
        if offline { throw RestClient.RestError.connectionLost }
        let commodity = try XCTUnwrap(request.commodityId, "Preparation requires individual Commodity coverage")
        XCTAssertNil(request.commodityGroupId)
        let responseName = seasonName
        seasonRequests.append("\(commodity):\(request.page)")
        if commodity == "beans", request.page == 2, failingBeanContinuation { throw CocoaError(.fileReadUnknown) }
        if commodity == "beans", request.page == 2, let seasonEntered {
            self.seasonEntered = nil
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                seasonEntered.fulfill()
            }
        }
        if commodity == "rice", let riceEntered {
            self.riceEntered = nil
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                riceEntered.fulfill()
            }
        }
        if failingCommodities.contains(commodity) { throw CocoaError(.fileReadUnknown) }
        if let replacement = replacements[commodity] {
            return .init(data: replacement, pagination: .init(pageSize: 100, nextPage: nil, previousPage: nil,
                count: replacement.count, totalPages: 1, page: 1))
        }
        let statuses: [ResponseModels.HarvestSeason.Status]
        if commodity == "empty" { statuses = [] } else if commodity == "beans" {
            statuses = request.page == 1 ? [.active, .past] : [.archived]
        } else { statuses = [.active] }
        let data = statuses.map { status in
            ResponseModels.HarvestSeason(id: commodity + "-" + (status == .archived ? "archive" : status.rawValue),
                name: responseName ?? status.rawValue, startDate: "2025-09-01", endDate: "2026-09-01", status: status)
        }
        return .init(data: data, pagination: .init(pageSize: 2,
            nextPage: commodity == "beans" && request.page == 1 && !truncatedSeasons ? 2 : nil,
            previousPage: request.page == 2 ? 1 : nil, count: commodity == "beans" ? 3 : data.count,
            totalPages: commodity == "beans" ? 2 : 1, page: request.page))
    }
}

final class PreloadConnectivity: Connectivity {
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> { Just(.reachable(.ethernetOrWiFi)).eraseToAnyPublisher() }
    var isReachableValue: ConnectivityImpl.Status { .reachable(.ethernetOrWiFi) }
    var isReachableFlag: Bool { true }
    func startObserving() { }
    func stopObserving() { }
}

struct PreloadUnusedBalance: SeasonalBalanceRepository {
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        XCTFail("Buyer and Producer creation must not prefetch a balance")
        throw SeasonalBalanceError.unavailableCache
    }
}

final class PreloadUnrelatedData: ProfileInteractor, NotificationsSettingsInteractor, NotificationsInteractor,
    TransactionListInteractor {
    var query: TransactionListQuery { .init() }
    func fetchProfile() async throws { }
    func fetchProfileFromCache() async throws { }
    func fetchSettings() async throws { }
    func updateSettings(_ settingsList: IdentifiedArrayOf<NotificationsSettingsModel>) async throws { }
    func fetchNotifications(notificationTypes: [RequestModels.NotificationsList.NotificationType], refresh: Bool) async throws { }
    func fetchNotificationsFromCache() async throws { }
    func setQuery(_ query: TransactionListQuery) { }
    func refresh(cacheOnly: Bool) async { }
    func loadNextPage() async { }
}

final class PreloadBalanceData: BalanceListInteractor {
    var query: BalanceListQuery { .init() }
    func setQuery(_ query: BalanceListQuery) { }
    func refresh(cacheOnly: Bool) async { }
    func loadNextPage() async { }
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance { throw SeasonalBalanceError.unavailableCache }
    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance { throw SeasonalBalanceError.unavailableCache }
}

final class PreloadUnusedCleaner: DataCleanerInteractor {
    func resetBusinessData() async throws { XCTFail("Unexpected cleanup") }
    func dropAll() async throws { XCTFail("An authenticated startup must retain the cache") }
}

final class PreloadUnusedSync: OfflineTransactionsSyncInteractor {
    func discardPendingResults() async { }
    func syncTransactions() async throws { }
}

actor PreloadWriteGate {
    let entered: XCTestExpectation
    private var continuation: CheckedContinuation<Void, Never>?
    private let onlyFirst: Bool
    private var hasWaited = false
    init(entered: XCTestExpectation, onlyFirst: Bool = false) { self.entered = entered; self.onlyFirst = onlyFirst }
    func wait() async {
        if onlyFirst && hasWaited { return }
        hasWaited = true
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            entered.fulfill()
        }
    }
    func release() { continuation?.resume(); continuation = nil }
}

final class PreloadPausedDatabase: DatabaseKit.Database {
    let database: DatabaseKit.Database
    let gate: PreloadWriteGate
    init(database: DatabaseKit.Database, gate: PreloadWriteGate) { self.database = database; self.gate = gate }
    var reader: any DatabaseReader { database.reader }
    func save<T: MutableStorePersistable>(_ model: T) async throws -> T { try await database.save(model) }
    func update<T: MutableStorePersistable>(_ model: T) async throws { try await database.update(model) }
    func delete<T: MutableStorePersistable>(_ model: T) async throws -> Bool {
        await gate.wait()
        return try await database.delete(model)
    }
    func flush() async throws { try await database.flush() }
    func find<T: MutableStorePersistable>(_ modelType: T.Type, key: some DatabaseValueConvertible) async throws -> T {
        try await database.find(modelType, key: key)
    }
    func readCount<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> Int { try await database.readCount(request) }
    func save(_ writeClosure: @escaping (GRDB.Database) throws -> Void) async throws {
        await gate.wait()
        try await database.save(writeClosure)
    }
    func readOne<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> T? {
        try await database.readOne(request)
    }
    func readAll<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> [T] {
        try await database.readAll(request)
    }
}
