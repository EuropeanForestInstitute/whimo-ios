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

extension CataloguePreloadTests {
    func testRootReconnectionRecoversMissingSeasonsForOfflineProducerCreation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        await target.failBeanContinuation(true)
        let connectivity = PreloadMutableConnectivity()
        let preload = makePreload(database: fixture.database, target: target, connectivity: connectivity)
        let observer = PreloadLifecycleObserver(preload: preload)
        let initial = expectation(description: "Initial partial preparation finished")
        await observer.observeEntry(initial)
        let state = FilterAppStateTestDouble()
        let root = makeRoot(preload: observer, connectivity: connectivity, state: state)
        await fulfillment(of: [initial], timeout: 3)
        await target.goOffline()
        connectivity.send(.notReachable)
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: fixture.database, target: target),
            balances: PreloadUnusedBalance())
        do {
            _ = try await creation.seasons(commodityId: "beans")
            XCTFail("The interrupted Commodity must remain unavailable")
        } catch CreationSeasonError.catalogueRequired { }

        await target.failBeanContinuation(false)
        await target.goOnline()
        let recovered = expectation(description: "Reconnection preparation finished")
        await observer.observeRecovery(recovered)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [recovered], timeout: 3)
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "beans:1", "beans:2"])
        await target.goOffline()
        connectivity.send(.notReachable)
        let commodities = try await makeCommodities(database: fixture.database, target: target).fetchCommodityGroups()
        let beans = try XCTUnwrap(commodities.flatMap(\.commodities).first { $0.id == "beans" })
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: BuyerTransactionTarget(), transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let local = fixture.local()
        state.transactions[\.list] = .loaded(value: [])
        let transactions = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local, creationSeasonInteractor: creation)
        try await transactions.createProducerTransaction(farmLocation: nil, commodityType: beans, volume: "12",
            isBuyingFromFarmer: true, transactionCoordinates: nil, inviteRecipient: nil)
        let queued = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(queued.map(\.harvestSeasonId), ["beans-active"])
        withExtendedLifetime(root) { }
    }

    func testRepeatedEntryAndReconnectionSharePendingPreparationAndOneSubscription() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        await target.failBeanContinuation(true)
        let connectivity = PreloadMutableConnectivity()
        let preload = makePreload(database: database, target: target, connectivity: connectivity)
        let observer = PreloadLifecycleObserver(preload: preload)
        let initial = expectation(description: "Initial attempt finished")
        await observer.observeEntry(initial)
        let state = FilterAppStateTestDouble()
        let root = makeRoot(preload: observer, connectivity: connectivity, state: state)
        await fulfillment(of: [initial], timeout: 3)
        connectivity.send(.notReachable)
        await target.failBeanContinuation(false)
        let pending = expectation(description: "Recovery response pending")
        await target.pauseBeanContinuation(entered: pending)
        let recovered = expectation(description: "Recovery completed")
        await observer.observeRecovery(recovered)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [pending], timeout: 3)

        let entryStarted = expectation(description: "Overlapping entry started")
        let entryFinished = expectation(description: "Overlapping entry completed")
        await observer.observeEntry(entryFinished, started: entryStarted)
        state.navigation.send(.authorized)
        await fulfillment(of: [entryStarted], timeout: 3)
        XCTAssertEqual(connectivity.subscriptions, 1)
        let reconnectStarted = expectation(description: "Overlapping reconnect started")
        let reconnectFinished = expectation(description: "Overlapping reconnect completed")
        await observer.observeRecovery(reconnectFinished, started: reconnectStarted)
        connectivity.send(.notReachable)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [reconnectStarted], timeout: 3)
        await target.resume()
        await fulfillment(of: [recovered, entryFinished, reconnectFinished], timeout: 3)
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "beans:1", "beans:2"])
        XCTAssertEqual(connectivity.subscriptions, 1)
        withExtendedLifetime(root) { }
    }

    func testSubsequentRootEntryReopensPartialDatabaseAndSkipsNonemptyAndEmptySnapshots() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = PreloadCatalogueTarget()
        await target.failBeanContinuation(true)
        await makePreload(database: fixture.database, target: target).prepareCatalogues()
        await target.failBeanContinuation(false)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let connectivity = PreloadMutableConnectivity()
        let observer = PreloadLifecycleObserver(preload: makePreload(database: reopened, target: target, connectivity: connectivity))
        let finished = expectation(description: "Reopened Root preparation finished")
        await observer.observeEntry(finished)
        let root = makeRoot(preload: observer, connectivity: connectivity, state: FilterAppStateTestDouble())
        await fulfillment(of: [finished], timeout: 3)
        let pages = await target.groupPages
        let requests = await target.seasonRequests
        XCTAssertEqual(pages, [1, 2])
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "beans:1", "beans:2"])
        await target.goOffline()
        let restored = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let seasons = try await makeSeasons(database: restored, target: target).seasons(commodityId: "beans")
        XCTAssertEqual(seasons.values.map(\.id), ["beans-active", "beans-past", "beans-archive"])
        withExtendedLifetime(root) { }
    }

    func testRootReconnectionFinishesInterruptedInitialCommodityCatalogue() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        await target.truncateGroups(true)
        let connectivity = PreloadMutableConnectivity()
        let observer = PreloadLifecycleObserver(preload: makePreload(database: database, target: target, connectivity: connectivity))
        let initial = expectation(description: "Incomplete catalogue attempt finished")
        await observer.observeEntry(initial)
        let root = makeRoot(preload: observer, connectivity: connectivity, state: FilterAppStateTestDouble())
        await fulfillment(of: [initial], timeout: 3)
        connectivity.send(.notReachable)
        await target.truncateGroups(false)
        let recovered = expectation(description: "Initial catalogue recovery finished")
        await observer.observeRecovery(recovered)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [recovered], timeout: 3)
        let pages = await target.groupPages
        XCTAssertEqual(pages, [1, 1, 2])
        await target.goOffline()
        let groups = try await makeCommodities(database: database, target: target).fetchCommodityGroups()
        XCTAssertEqual(Set(groups.flatMap(\.commodities).map(\.id)), ["beans", "coffee", "empty"])
        withExtendedLifetime(root) { }
    }

    func testFailedSeasonStorageRemainsMissingAcrossDatabaseReopening() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        try await fixture.database.save { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_season_preparation BEFORE INSERT ON seasonCatalogueCache
                WHEN NEW.id = 'commodity:beans'
                BEGIN SELECT RAISE(ABORT, 'injected season failure'); END;
                """)
        }
        let target = PreloadCatalogueTarget()
        await makePreload(database: fixture.database, target: target).prepareCatalogues()
        try await fixture.database.save { db in try db.execute(sql: "DROP TRIGGER fail_season_preparation") }
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        await makePreload(database: reopened, target: target).prepareCatalogues()
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "coffee:1", "empty:1", "beans:1", "beans:2"])
        await target.goOffline()
        let seasons = try await makeSeasons(database: reopened, target: target).seasons(commodityId: "beans")
        XCTAssertEqual(seasons.values.count, 3)
    }

    func testCancelledPreparationCanResumeBeforeOldTransportReturns() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Cancelled season response pending")
        await target.pauseBeanContinuation(entered: entered)
        let preload = makePreload(database: database, target: target)
        let old = Task { await preload.prepareCatalogues() }
        await fulfillment(of: [entered], timeout: 3)
        await preload.cancelCataloguePreparation()
        await preload.prepareCatalogues()
        await target.resume()
        await old.value
        await preload.prepareCatalogues()
        let requests = await target.seasonRequests
        XCTAssertEqual(requests, ["beans:1", "beans:2", "beans:1", "beans:2", "coffee:1", "empty:1"])
        await target.goOffline()
        let seasons = try await makeSeasons(database: database, target: target).seasons(commodityId: "beans")
        XCTAssertEqual(seasons.values.count, 3)
    }

    func testDelayedPreparationDoesNotReplaceCompletedOnlineSeasonRefresh() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Old preparation response pending")
        await target.pauseBeanContinuation(entered: entered)
        let preload = makePreload(database: database, target: target)
        let pending = Task { await preload.prepareCatalogues() }
        await fulfillment(of: [entered], timeout: 3)
        await target.setSeasonName("Updated season")
        let catalogue = makeSeasons(database: database, target: target)
        let fresh = try await catalogue.seasons(commodityId: "beans")
        XCTAssertEqual(fresh.values.map(\.name), ["Updated season", "Updated season", "Updated season"])
        await target.resume()
        await pending.value
        await target.goOffline()
        let retained = try await catalogue.seasons(commodityId: "beans")
        XCTAssertEqual(retained.values.map(\.name), ["Updated season", "Updated season", "Updated season"])
    }

    func testLogoutCleanupAndNextAccountEntryInvalidatePendingLifecyclePreparation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "preload-cleanup-" + UUID().uuidString))
        defer { defaults.clear() }
        let account: () -> String? = { (fixture.storage.get(.user) as UserModel?)?.id }
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Old account preparation pending")
        await target.pauseBeanContinuation(entered: entered)
        let connectivity = PreloadMutableConnectivity()
        let preload = makePreload(database: fixture.database, target: target, accountId: account, connectivity: connectivity)
        let observer = PreloadLifecycleObserver(preload: preload)
        let oldFinished = expectation(description: "Cancelled lifecycle call finishes")
        await observer.observeEntry(oldFinished)
        let state = FilterAppStateTestDouble()
        let root = makeRoot(preload: observer, connectivity: connectivity, state: state)
        await fulfillment(of: [entered], timeout: 3)
        let repositories = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: preload, database: fixture.database,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: repositories, offlineTransactionsSyncInteractor: PreloadUnusedSync(),
            keychainStore: fixture.storage, userDefaultsStore: defaults)
        try await cleaner.dropAll()
        XCTAssertNil(account())
        let loggedOut = expectation(description: "Logged-out reconnect is ignored")
        await observer.observeRecovery(loggedOut)
        connectivity.send(.notReachable)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [loggedOut], timeout: 3)
        let beforeNewAccount = await target.groupPages
        XCTAssertEqual(beforeNewAccount, [1, 2])

        fixture.storage.set(UserModel(id: "new-account", username: "Fixture", gadgets: []), key: .user)
        await target.setSeasonName("New account season")
        let newFinished = expectation(description: "New account preparation finishes")
        await observer.observeEntry(newFinished)
        state.navigation.send(.authorized)
        await fulfillment(of: [newFinished], timeout: 3)
        await target.resume()
        await fulfillment(of: [oldFinished], timeout: 3)
        await target.goOffline()
        let seasons = try await makeSeasons(database: fixture.database, target: target, accountId: account).seasons(commodityId: "beans")
        XCTAssertEqual(seasons.values.map(\.name), ["New account season", "New account season", "New account season"])
        XCTAssertEqual(connectivity.subscriptions, 1)
        withExtendedLifetime(root) { }
    }

    func testReconnectBeforeOldCatalogueFailureRetainsOneRecoveryPass() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = PreloadCatalogueTarget()
        let entered = expectation(description: "Initial catalogue response pending")
        await target.pauseFirstPage(entered: entered, failOnResume: true)
        let connectivity = PreloadMutableConnectivity()
        let observer = PreloadLifecycleObserver(preload: makePreload(database: database, target: target, connectivity: connectivity))
        let initialFinished = expectation(description: "Initial lifecycle preparation finishes")
        await observer.observeEntry(initialFinished)
        let root = makeRoot(preload: observer, connectivity: connectivity, state: FilterAppStateTestDouble())
        await fulfillment(of: [entered], timeout: 3)
        let recoveryStarted = expectation(description: "Reconnect joins pending request")
        let recoveryFinished = expectation(description: "Recovery finishes after late failure")
        await observer.observeRecovery(recoveryFinished, started: recoveryStarted)
        connectivity.send(.notReachable)
        connectivity.send(.reachable(.ethernetOrWiFi))
        await fulfillment(of: [recoveryStarted], timeout: 3)
        await target.resume()
        await fulfillment(of: [initialFinished, recoveryFinished], timeout: 3)
        let pages = await target.groupPages
        XCTAssertEqual(pages, [1, 1, 2], "The recovered connection must finish missing work without another event")
        await target.goOffline()
        let groups = try await makeCommodities(database: database, target: target).fetchCommodityGroups()
        XCTAssertEqual(Set(groups.flatMap(\.commodities).map(\.id)), ["beans", "coffee", "empty"])
        withExtendedLifetime(root) { }
    }

    func makeRoot(preload: DataFetcherInteractor, connectivity: any Connectivity,
                  state: FilterAppStateTestDouble,
                  sync: OfflineTransactionsSyncInteractor = PreloadUnusedSync()) -> RootModule.ViewModel {
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "preload-root-" + UUID().uuidString))
        defaults.set(true, key: .isLoggedIn)
        addTeardownBlock { defaults.clear() }
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { preload }.scope(.unique)
        AppContainer.shared.userDefaultsStore.register { defaults }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.connectivity.register { connectivity }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { PreloadUnusedCleaner() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { sync }.scope(.unique)
        return RootModule.ViewModel()
    }

}

// The lifecycle fixture awaits the production catalogue operation in place of unrelated remote preload,
// exposing deterministic completion while retaining real catalogue repositories and SQLite.
actor PreloadLifecycleObserver: DataFetcherInteractor {
    let preload: DataFetcherInteractorImpl
    private var entry: XCTestExpectation?
    private var recovery: XCTestExpectation?
    private var entryStarted: XCTestExpectation?
    private var recoveryStarted: XCTestExpectation?
    init(preload: DataFetcherInteractorImpl) { self.preload = preload }
    func observeEntry(_ expectation: XCTestExpectation, started: XCTestExpectation? = nil) {
        entry = expectation
        entryStarted = started
    }
    func observeRecovery(_ expectation: XCTestExpectation, started: XCTestExpectation? = nil) {
        recovery = expectation
        recoveryStarted = started
    }
    func loadCacheData() async { await preload.loadCacheData() }
    func fetchRemoteData() async {
        entryStarted?.fulfill()
        entryStarted = nil
        let completion = entry
        entry = nil
        await preload.prepareCatalogues()
        completion?.fulfill()
    }
    func prepareCatalogues() async {
        recoveryStarted?.fulfill()
        recoveryStarted = nil
        let completion = recovery
        recovery = nil
        await preload.prepareCatalogues()
        completion?.fulfill()
    }
    func startCataloguePreparation() async { await preload.startCataloguePreparation() }
    func cancelCataloguePreparation() async { await preload.cancelCataloguePreparation() }
}

final class PreloadMutableConnectivity: Connectivity {
    private let subject = CurrentValueSubject<ConnectivityImpl.Status, Never>(.reachable(.ethernetOrWiFi))
    var subscriptions = 0
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> {
        subject.handleEvents(receiveSubscription: { [weak self] _ in self?.subscriptions += 1 }).eraseToAnyPublisher()
    }
    var isReachableValue: ConnectivityImpl.Status { subject.value }
    var isReachableFlag: Bool { if case .reachable = subject.value { return true }; return false }
    func send(_ status: ConnectivityImpl.Status) { subject.send(status) }
    func startObserving() { }
    func stopObserving() { }
}

final class PreloadCleanupRepositories: AuthRepository, ProfileCachingRepository {
    func signUp(contactIdentifier: ContactIdentifier, password: String) async throws { XCTFail("Unexpected authentication") }
    func signIn(contactIdentifier: ContactIdentifier, password: String) async throws { XCTFail("Unexpected authentication") }
    func signInWithGoogle(idToken: String) async throws { XCTFail("Unexpected authentication") }
    func signInWithApple(idToken: String, nonce: String) async throws { XCTFail("Unexpected authentication") }
    func sendOTP(gadgetId: String, captchaToken: String) async throws { XCTFail("Unexpected authentication") }
    func verifyOTP(gadgetId: String, code: String) async throws { XCTFail("Unexpected authentication") }
    func sendPasswordReset(gadgetId: String, captchaToken: String) async throws { XCTFail("Unexpected authentication") }
    func checkPasswordReset(gadgetId: String, code: String) async throws { XCTFail("Unexpected authentication") }
    func verifyPasswordReset(gadgetId: String, pass: String, code: String) async throws { XCTFail("Unexpected authentication") }
    func fetchProfile() async throws -> UserModel { throw CancellationError() }
    func changePassword(currentPassword: String, newPassword: String) async throws { XCTFail("Unexpected authentication") }
    func deleteProfile() async throws { XCTFail("Unexpected authentication") }
    func flush() { }
}
