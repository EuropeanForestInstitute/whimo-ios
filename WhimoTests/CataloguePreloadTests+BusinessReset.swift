//
//  CataloguePreloadTests+BusinessReset.swift
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
import StorageKit
import RestClient
import Networking
@testable import Whimo

extension CataloguePreloadTests {
    func testOfflineModeRoundTripRetainsSharedCataloguesAndClearsBalancesUntilLogout() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.preload.prepareCatalogues()
        let catalogue = makeCommodities(database: scenario.fixture.database, target: scenario.catalogue)
        let groups = try await catalogue.prepareCatalogue()
        let seasons = try await scenario.fixture.database.readAll(SeasonCatalogueCache.all())
        let expectedSnapshots = Dictionary(uniqueKeysWithValues: seasons.map { ($0.id, $0.payload) })
        XCTAssertFalse(groups.isEmpty)
        XCTAssertNotNil(expectedSnapshots["selection:commodities"])
        XCTAssertNotNil(expectedSnapshots["commodity:beans"])
        XCTAssertNotNil(expectedSnapshots["commodity:empty"], "A completed empty catalogue must also survive")
        await scenario.catalogue.goOffline()

        for enabled in [true, false] {
            let balanceTarget = BalanceTargetDouble()
            try await balanceTarget.returnBalance(volume: 27, commodityId: "beans", seasonId: "captured")
            let balances = makeIntegratedBalances(database: scenario.fixture.database, target: balanceTarget)
            _ = try await balances.exact(commodityId: "beans", seasonId: "captured")
            try await scenario.fixture.database.save { db in
                try DatabaseKit.Commodity.updateAll(db, DatabaseKit.Commodity.Columns.balance.set(to: 93))
            }
            await scenario.settings.setTestModeEnabled(enabled)
            if enabled { await scenario.settings.confirmTestModeEntry() }
            XCTAssertEqual(scenario.mode.mode, enabled ? .test : .ordinary)

            let reopened = try DatabaseImpl(writer: DatabaseQueue(path: scenario.fixture.databasePath))
            let retained = try await makeCommodities(database: reopened, target: scenario.catalogue).prepareCatalogue()
            XCTAssertEqual(retained, groups, "Catalogue preparation must remain usable offline after each switch")
            let retainedSnapshots = try await reopened.readAll(SeasonCatalogueCache.all())
            XCTAssertEqual(Dictionary(uniqueKeysWithValues: retainedSnapshots.map { ($0.id, $0.payload) }), expectedSnapshots)
            let retainedSeasons = try await makeSeasons(database: reopened, target: scenario.catalogue).seasons(commodityId: "beans")
            XCTAssertFalse(retainedSeasons.values.isEmpty)
            let remainingBalances = try await reopened.readCount(SeasonalBalanceCache.all())
            XCTAssertEqual(remainingBalances, 0)
            let commodities = try await reopened.readAll(DatabaseKit.Commodity.all())
            XCTAssertTrue(commodities.allSatisfy { $0.balance == nil })
            XCTAssertEqual(scenario.state.balance.value, .initialState)
        }

        try await scenario.cleaner.dropAll()
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: scenario.fixture.databasePath))
        let remainingGroups = try await reopened.readCount(DatabaseKit.CommodityGroup.all())
        let remainingCommodities = try await reopened.readCount(DatabaseKit.Commodity.all())
        let remainingSeasons = try await reopened.readCount(SeasonCatalogueCache.all())
        XCTAssertEqual(remainingGroups, 0)
        XCTAssertEqual(remainingCommodities, 0)
        XCTAssertEqual(remainingSeasons, 0)
    }

    func testBusinessResetRejectsDelayedCatalogueResponseForRetainedParticipant() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-delay-" + UUID().uuidString))
        defer { defaults.clear() }
        let target = PreloadCatalogueTarget()
        let context = BusinessDataContext()
        let seasons = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target, database: fixture.database,
            mapper: SeasonCatalogueMapper(), accountId: { "fixture-buyer" }, businessDataContext: context)
        let entered = expectation(description: "Old business response suspended")
        await target.pauseBeanContinuation(entered: entered)
        let pending = Task { try await seasons.seasons(commodityId: "beans") }
        await fulfillment(of: [entered], timeout: 3)
        let unused = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: FilterAppStateTestDouble(),
            dataFetcherInteractor: makePreload(database: fixture.database, target: target), database: fixture.database,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: unused, offlineTransactionsSyncInteractor: PreloadUnusedSync(), keychainStore: fixture.storage,
            userDefaultsStore: defaults, businessDataContext: context)
        try await cleaner.resetBusinessData()
        await target.resume()
        do {
            _ = try await pending.value
            XCTFail("The retained participant must not make an old business response current")
        } catch is CancellationError { }
        await target.goOffline()
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        do {
            _ = try await makeSeasons(database: reopened, target: target).seasons(commodityId: "beans")
            XCTFail("Old-context data must not reappear after reopening")
        } catch { }
    }

    func testBusinessResetRejectsDelayedConfirmedUploadWithoutRestoringQueueOrReceipt() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-sync-" + UUID().uuidString))
        defer { defaults.clear() }
        let catalogueTarget = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: catalogueTarget)
        await preload.prepareCatalogues()
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: fixture.database, target: catalogueTarget),
            balances: PreloadUnusedBalance())
        let target = BuyerTransactionTarget()
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: [])
        let transactions = try makeIntegratedTransactions(fixture: fixture, target: target, state: state, creation: creation)
        let selected = try await creation.seasons(commodityId: "beans").values.first
        try await transactions.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
            commodityType: BuyerVolumeTests.commodity, volume: "10", action: .buy,
            recipient: .init(recipientID: "supplier", email: "", phone: ""),
            seasonSelection: .init(commodityId: "beans", season: XCTUnwrap(selected)))
        let queue = try await fixture.local().fetchOnDiskTransactions()
        let queued = try XCTUnwrap(queue.first)
        let context = BusinessDataContext()
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: fixture.local(),
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target,
            transactionsMapper: fixture.mapper, businessDataContext: context)
        await target.goOnline()
        let entered = expectation(description: "Upload response held after submission")
        await target.pauseNextCreate(entered: entered)
        let pending = Task { try await sync.syncTransactions() }
        await fulfillment(of: [entered], timeout: 3)
        let files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        let unused = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: preload,
            database: fixture.database, fileStorage: files, authRepository: unused, offlineTransactionsSyncInteractor: sync,
            keychainStore: fixture.storage, userDefaultsStore: defaults, businessDataContext: context)
        try await cleaner.resetBusinessData()
        await target.resumeCreate()
        do {
            try await pending.value
            XCTFail("Discarded upload results must not be published or journaled")
        } catch is CancellationError { }
        let reopened = try fixture.reopenedLocal()
        let rows = try await reopened.fetchTransactions(with: .initial())
        XCTAssertTrue(rows.list.isEmpty)
        XCTAssertTrue(state.transactions.value.list.value?.isEmpty ?? true)
        XCTAssertTrue(state.transactions.value.updatingList.isEmpty)
        XCTAssertNil(try files.confirmedUploadID(for: queued.id))
        try await sync.syncTransactions()
        let attempts = await target.requests
        XCTAssertEqual(attempts.count, 2, "One offline attempt and one discarded upload; reset must not retry")
    }

    func testAuthorizedRootPreloadCannotRestoreDiscardedBalances() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-root-" + UUID().uuidString))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        let context = BusinessDataContext()
        let state = FilterAppStateTestDouble()
        let target = BalanceTargetDouble()
        try await target.returnBalance(volume: 27, commodityId: "beans", seasonId: "captured")
        let balances = SeasonalBalanceRepositoryImpl(target: target, database: fixture.database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()),
            accountId: { "fixture-buyer" }, businessDataContext: context)
        let list = BalanceListInteractorImpl(appState: state, repository: balances, businessDataContext: context)
        let profile = ProfileLocalRepositoryImpl(keychainStore: fixture.storage, userMapper: UserMapper())
        let profileCache = ProfileCachingRepositoryImpl(localRepo: profile, remoteRepo: ResetOfflineProfile(), businessDataContext: context)
        let profileInteractor = ProfileInteractorImpl(appState: state, profileCachingRepository: profileCache,
            profileLocalRepository: profile, businessDataContext: context)
        let unused = PreloadUnrelatedData()
        let catalogue = PreloadCatalogueTarget()
        let offline = CatalogueOfflineConnectivity()
        let preload = DataFetcherInteractorImpl(profileInteractor: profileInteractor, notificationsSettingsInteractor: unused,
            transactionsInteractor: unused, balanceInteractor: list, notificationsInteractor: unused, connectivity: offline,
            commodityRepository: makeCommodities(database: fixture.database, target: catalogue),
            seasonRepository: makeSeasons(database: fixture.database, target: catalogue), accountId: { "fixture-buyer" }, businessDataContext: context)
        let finished = expectation(description: "Authorized preload completed")
        let observer = ResetObservedPreload(preload: preload, finished: finished)
        let cleanupRepositories = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: observer, database: fixture.database,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: cleanupRepositories, offlineTransactionsSyncInteractor: PreloadUnusedSync(),
            keychainStore: fixture.storage, userDefaultsStore: defaults, businessDataContext: context)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.businessDataContext.register { context }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { profile }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { observer }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { cleaner }.scope(.unique)
        AppContainer.shared.userDefaultsStore.register { defaults }.scope(.unique)
        AppContainer.shared.connectivity.register { offline }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { PreloadUnusedSync() }.scope(.unique)
        let entered = expectation(description: "Authorized balance response suspended")
        await target.pauseNext(entered: entered)
        let root = RootModule.ViewModel()
        await fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        try await cleaner.resetBusinessData()
        await target.resume()
        await fulfillment(of: [finished], timeout: 3)
        XCTAssertEqual(state.balance.value.list, .notRequested)
        XCTAssertEqual(try profile.fetchProfile().id, "fixture-buyer")
        await target.goOffline()
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        do {
            _ = try await makeIntegratedBalances(database: reopened, target: target).cachedExact(commodityId: "beans", seasonId: "captured")
            XCTFail("Old preload must not recreate a durable balance snapshot")
        } catch { }
        withExtendedLifetime(root) { }
    }

    func testBusinessResetRetainsSessionAndPreferencesAcrossRecreation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let suite = "business-reset-" + UUID().uuidString
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: suite))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        defaults.set("fr", key: .currentLocalize)
        defaults.set(false, key: .isFirstLaunch)
        fixture.storage.set("synthetic-access", key: .accessToken)
        fixture.storage.set("synthetic-refresh", key: .refreshToken)
        let state = FilterAppStateTestDouble()
        let profile = ProfileLocalRepositoryImpl(keychainStore: fixture.storage, userMapper: UserMapper())
        let participant = try profile.fetchProfile()
        state.profile[\.userModel] = .loaded(value: participant)
        state.balance[\.query] = .init(search: "discarded")
        state.transactions[\.query] = .init(search: "discarded")
        state.createTransaction[\.volumeAmount] = "17"
        state.system[\.selectedTab] = .settings
        state.system[\.isLoading] = true
        state.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true), .push(.notificationsList)]
        let preference = NotificationsSettingsModel(type: .geodataMissing, isEnabled: false)
        let settings = NotificationsSettingsLocalRepositoryImpl(database: fixture.database, notificationsSettingsMapper: NotificationsSettingsMapper())
        try await settings.save(preference)
        state.notificationsSettings[\.settingsList] = .init(uniqueElements: [preference])
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        await preload.prepareCatalogues()
        let balanceTarget = BalanceTargetDouble()
        await balanceTarget.goOffline()
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: fixture.database, target: target),
            balances: makeIntegratedBalances(database: fixture.database, target: balanceTarget))
        let transactions = try makeIntegratedTransactions(fixture: fixture, target: BuyerTransactionTarget(), state: state, creation: creation)
        let groups = try await makeCommodities(database: fixture.database, target: target).fetchCommodityGroups()
        let beans = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "beans" })
        let coffee = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "coffee" })
        try await createPreparedQueue(transactions: transactions, creation: creation, beans: beans, coffee: coffee)
        let queued = try await fixture.local().fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 4)
        let files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        for transaction in queued { try files.saveConfirmedUploadID("confirmed-" + transaction.id, for: transaction.id) }
        let unused = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: preload,
            database: fixture.database, fileStorage: files, authRepository: unused, offlineTransactionsSyncInteractor: PreloadUnusedSync(),
            keychainStore: fixture.storage, userDefaultsStore: defaults)

        try await cleaner.resetBusinessData()

        XCTAssertEqual(try profile.fetchProfile(), participant)
        XCTAssertEqual(fixture.storage.get(.accessToken) as String?, "synthetic-access")
        XCTAssertEqual(fixture.storage.get(.refreshToken) as String?, "synthetic-refresh")
        let reopenedDefaults = AnyStorage(state: UserDefaultsStore(suiteName: suite))
        XCTAssertEqual(reopenedDefaults.get(.isLoggedIn) as Bool?, true)
        XCTAssertEqual(reopenedDefaults.get(.currentLocalize) as String?, "fr")
        XCTAssertEqual(reopenedDefaults.get(.isFirstLaunch) as Bool?, false)
        XCTAssertEqual(state.balance.value.query, .init())
        XCTAssertEqual(state.transactions.value.query, .init())
        XCTAssertEqual(state.createTransaction.value.volumeAmount, "")
        XCTAssertFalse(state.system.value.isLoading)
        XCTAssertEqual(state.system.value.selectedTab, .settings)
        XCTAssertEqual(state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(Array(state.notificationsSettings.value.settingsList), [preference])
        XCTAssertEqual(state.profile.value.userModel.value, participant)
        await target.goOffline()
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let reopenedGroups = try await makeCommodities(database: reopened, target: target).fetchCommodityGroups()
        XCTAssertEqual(reopenedGroups, groups)
        let remaining = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(remaining.isEmpty)
        for transaction in queued {
            XCTAssertNil(try files.confirmedUploadID(for: transaction.id))
            let evidence = try XCTUnwrap(transaction.persistingData.farmLocationFile?.fileURL)
            XCTAssertFalse(FileManager.default.fileExists(atPath: evidence.path))
        }
        let savedSettings = try await NotificationsSettingsLocalRepositoryImpl(database: reopened,
            notificationsSettingsMapper: NotificationsSettingsMapper()).fetchSettingsList()
        XCTAssertEqual(Array(savedSettings), [preference])
        let reopenedStorage = AnyStorage(state: KeychainStore(bundleIdentifier: fixture.keychainService))
        let reopenedProfile = ProfileLocalRepositoryImpl(keychainStore: reopenedStorage, userMapper: UserMapper())
        XCTAssertEqual(try reopenedProfile.fetchProfile(), participant)
        XCTAssertEqual(reopenedStorage.get(.accessToken) as String?, "synthetic-access")
        XCTAssertEqual(reopenedStorage.get(.refreshToken) as String?, "synthetic-refresh")
        let coldState = FilterAppStateTestDouble()
        let coldProfile = ProfileInteractorImpl(appState: coldState,
            profileCachingRepository: ProfileCachingRepositoryImpl(localRepo: reopenedProfile, remoteRepo: ResetOfflineProfile()),
            profileLocalRepository: reopenedProfile)
        let coldPreload = makePreload(database: reopened, target: target, connectivity: CatalogueOfflineConnectivity(), profileInteractor: coldProfile)
        AppContainer.shared.appState.register { coldState }.scope(.unique)
        AppContainer.shared.businessDataContext.register { BusinessDataContext() }.scope(.singleton)
        AppContainer.shared.profileLocalRepository.register { reopenedProfile }.scope(.unique)
        AppContainer.shared.userDefaultsStore.register { reopenedDefaults }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { coldPreload }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { PreloadUnusedCleaner() }.scope(.unique)
        AppContainer.shared.connectivity.register { CatalogueOfflineConnectivity() }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { PreloadUnusedSync() }.scope(.unique)
        let authorized = expectation(description: "Recreated offline root recognizes retained session")
        let subscription = coldState.navigation.activity.sink { if $0 == .authorized { authorized.fulfill() } }
        let root = RootModule.ViewModel()
        await fulfillment(of: [authorized], timeout: 3)
        await coldPreload.loadCacheData()
        XCTAssertEqual(coldState.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(coldState.profile.value.userModel.value, participant)
        withExtendedLifetime((root, subscription)) { }

    }
    func testLogoutClearsSessionPreferencesAndQueuedEvidenceAndOpensLogin() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "logout-reset-" + UUID().uuidString))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        fixture.storage.set("synthetic-access", key: .accessToken)
        let state = FilterAppStateTestDouble()
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        await preload.prepareCatalogues()
        let balanceTarget = BalanceTargetDouble()
        await balanceTarget.goOffline()
        let creation = CreationSeasonInteractorImpl(catalogue: makeSeasons(database: fixture.database, target: target),
            balances: makeIntegratedBalances(database: fixture.database, target: balanceTarget))
        let transactions = try makeIntegratedTransactions(fixture: fixture, target: BuyerTransactionTarget(), state: state, creation: creation)
        let groups = try await makeCommodities(database: fixture.database, target: target).fetchCommodityGroups()
        let beans = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "beans" })
        let coffee = try XCTUnwrap(groups.flatMap(\.commodities).first { $0.id == "coffee" })
        try await createPreparedQueue(transactions: transactions, creation: creation, beans: beans, coffee: coffee)
        let queue = try await fixture.local().fetchOnDiskTransactions()
        let files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        for transaction in queue { try files.saveConfirmedUploadID("confirmed-" + transaction.id, for: transaction.id) }
        try await NotificationsSettingsLocalRepositoryImpl(database: fixture.database, notificationsSettingsMapper: NotificationsSettingsMapper())
            .save(.init(type: .geodataMissing, isEnabled: false))
        let cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: preload,
            database: fixture.database, fileStorage: files, authRepository: PreloadCleanupRepositories(),
            offlineTransactionsSyncInteractor: PreloadUnusedSync(), keychainStore: fixture.storage, userDefaultsStore: defaults)
        let tokens = ResetTokenRegistry()
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { cleaner }.scope(.unique)
        AppContainer.shared.tokenRegistryService.register { tokens }.scope(.unique)
        await MoreModule.ViewModel.LogoutInteractor().logout()
        XCTAssertEqual(state.navigation.value.path, [.root(.login, embedInNavigationView: true)])
        XCTAssertNil(state.profile.value.userModel.value)
        XCTAssertEqual(tokens.fcmUpdates, [""])
        let reopenedStorage = AnyStorage(state: KeychainStore(bundleIdentifier: fixture.keychainService))
        XCTAssertNil(reopenedStorage.get(.user) as UserModel?)
        XCTAssertNil(reopenedStorage.get(.accessToken) as String?)
        XCTAssertNil(defaults.get(.isLoggedIn) as Bool?)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let preferences = try await NotificationsSettingsLocalRepositoryImpl(database: reopened,
            notificationsSettingsMapper: NotificationsSettingsMapper()).fetchSettingsList()
        XCTAssertTrue(preferences.isEmpty)
        let records = try await fixture.reopenedLocal().fetchTransactions(with: .initial())
        XCTAssertTrue(records.list.isEmpty)
        for transaction in queue {
            XCTAssertNil(try files.confirmedUploadID(for: transaction.id))
            let evidence = try XCTUnwrap(transaction.persistingData.farmLocationFile?.fileURL)
            XCTAssertFalse(FileManager.default.fileExists(atPath: evidence.path))
        }
    }

    func testBusinessResetClearsPreviouslyConfirmedUploadRecovery() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-recovery-" + UUID().uuidString))
        defer { defaults.clear() }
        let local = fixture.local()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        try await local.save(fixture.mapper.toDomain(from: seed.data))
        let queued = try await local.saveDownstreamTransaction(commodityId: "beans", volume: "300", location: nil,
            uploadFile: nil, farmCoordinates: nil, transactionCoordinates: nil, action: .buy,
            recipient: .name("fixture-supplier"), season: fixture.season)
        try await fixture.database.save { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_queue_replace BEFORE DELETE ON `transaction`
                BEGIN SELECT RAISE(ABORT, 'injected replacement failure'); END;
                """)
        }
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let state = FilterAppStateTestDouble()
        let context = BusinessDataContext()
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: local,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target,
            transactionsMapper: fixture.mapper, businessDataContext: context)
        do {
            try await sync.syncTransactions()
            XCTFail("Local replacement must fail after confirmation")
        } catch { }
        XCTAssertNotNil(try local.confirmedUploadID(for: queued))
        try await fixture.database.save { db in try db.execute(sql: "DROP TRIGGER fail_queue_replace") }
        let cleaner = DataCleanerInteractorImpl(appState: state,
            dataFetcherInteractor: makePreload(database: fixture.database, target: PreloadCatalogueTarget()), database: fixture.database,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: PreloadCleanupRepositories(), offlineTransactionsSyncInteractor: sync,
            keychainStore: fixture.storage, userDefaultsStore: defaults, businessDataContext: context)
        try await cleaner.resetBusinessData()
        XCTAssertNil(try local.confirmedUploadID(for: queued))
        // Reusing the identity makes stale in-memory recovery observable through public synchronization.
        try await local.save(queued)
        var record = fixture.mapper.toDatabase(from: queued)
        record.persistingData = .onDisk(farmLocationFile: nil)
        _ = try await fixture.database.save(record)
        let restoredQueue = try await local.fetchOnDiskTransactions()
        XCTAssertEqual(restoredQueue.map(\.id), [queued.id])
        try await sync.syncTransactions()
        let requests = await target.requests
        XCTAssertEqual(requests.count, 2, "A new context must not reuse a discarded confirmed result")
        let remaining = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(remaining.isEmpty)
    }

    func testResetRejectsAnOldDeletionWaitingForSQLite() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-delete-" + UUID().uuidString))
        defer { defaults.clear() }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        let transaction = fixture.mapper.toDomain(from: seed.data)
        try await fixture.local().save(transaction)
        let context = BusinessDataContext()
        let entered = expectation(description: "Old deletion waits for SQLite")
        let gate = PreloadWriteGate(entered: entered, onlyFirst: true)
        let files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        let local = TransactionsLocalRepositoryImpl(database: PreloadPausedDatabase(database: fixture.database, gate: gate),
            commoditiesGroupsMapper: CommoditiesGroupsMapper(), transactionsMapper: fixture.mapper,
            transactionsOfflineMapper: TransactionsOfflineMapper(), userMapper: UserMapper(), userOfflineMapper: UserOfflineMapper(),
            keychainStore: fixture.storage, fileStorage: files, businessDataContext: context)
        let deletion = Task { try await local.delete(transaction) }
        await fulfillment(of: [entered], timeout: 3)
        let cleaner = DataCleanerInteractorImpl(appState: FilterAppStateTestDouble(),
            dataFetcherInteractor: makePreload(database: fixture.database, target: PreloadCatalogueTarget()), database: fixture.database,
            fileStorage: files, authRepository: PreloadCleanupRepositories(), offlineTransactionsSyncInteractor: PreloadUnusedSync(),
            keychainStore: fixture.storage, userDefaultsStore: defaults, businessDataContext: context)
        try await cleaner.resetBusinessData()
        try await fixture.local().save(transaction)
        await gate.release()
        do {
            try await deletion.value
            XCTFail("An old deletion must not remove a new-context record")
        } catch is CancellationError { }
        let retained = try await fixture.reopenedLocal().fetchTransaction(by: transaction.id)
        XCTAssertEqual(retained.id, transaction.id)
    }

    func testLogoutWaitsForAnInProgressBusinessReset() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-logout-race-" + UUID().uuidString))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        fixture.storage.set("synthetic-access", key: .accessToken)
        let state = FilterAppStateTestDouble()
        let entered = expectation(description: "Business reset is suspended in SQLite")
        let gate = PreloadWriteGate(entered: entered, onlyFirst: true)
        let cleaner = DataCleanerInteractorImpl(appState: state,
            dataFetcherInteractor: makePreload(database: fixture.database, target: PreloadCatalogueTarget()),
            database: PreloadPausedDatabase(database: fixture.database, gate: gate),
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: PreloadCleanupRepositories(), offlineTransactionsSyncInteractor: PreloadUnusedSync(),
            keychainStore: fixture.storage, userDefaultsStore: defaults)
        let reset = Task { try await cleaner.resetBusinessData() }
        await fulfillment(of: [entered], timeout: 3)
        let logoutStarted = expectation(description: "Public Logout starts during reset")
        let tokens = ResetTokenRegistry()
        tokens.onUpdate = { logoutStarted.fulfill() }
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { cleaner }.scope(.unique)
        AppContainer.shared.tokenRegistryService.register { tokens }.scope(.unique)
        let logout = Task { await MoreModule.ViewModel.LogoutInteractor().logout() }
        await fulfillment(of: [logoutStarted], timeout: 3)
        await gate.release()
        try await reset.value
        await logout.value
        XCTAssertNil(fixture.storage.get(.accessToken) as String?)
        XCTAssertNil(fixture.storage.get(.user) as UserModel?)
        XCTAssertNil(defaults.get(.isLoggedIn) as Bool?)
        XCTAssertEqual(state.navigation.value.path, [.root(.login, embedInNavigationView: true)])
    }

    func testResetRejectsAnOldQueueWriteAlreadyWaitingForSQLite() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "reset-write-" + UUID().uuidString))
        defer { defaults.clear() }
        let target = PreloadCatalogueTarget()
        let preload = makePreload(database: fixture.database, target: target)
        await preload.prepareCatalogues()
        let context = BusinessDataContext()
        let entered = expectation(description: "Old queue write is waiting for SQLite")
        let gate = PreloadWriteGate(entered: entered)
        let files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        let local = TransactionsLocalRepositoryImpl(database: PreloadPausedDatabase(database: fixture.database, gate: gate),
            commoditiesGroupsMapper: CommoditiesGroupsMapper(), transactionsMapper: fixture.mapper,
            transactionsOfflineMapper: TransactionsOfflineMapper(), userMapper: UserMapper(), userOfflineMapper: UserOfflineMapper(),
            keychainStore: fixture.storage, fileStorage: files, businessDataContext: context)
        let pending = Task {
            try await local.saveDownstreamTransaction(commodityId: "beans", volume: "10", location: nil,
                uploadFile: nil, farmCoordinates: nil, transactionCoordinates: nil, action: .buy, recipient: .name("supplier"), season: fixture.season)
        }
        await fulfillment(of: [entered], timeout: 3)
        let cleaner = DataCleanerInteractorImpl(appState: FilterAppStateTestDouble(), dataFetcherInteractor: preload,
            database: fixture.database, fileStorage: files, authRepository: PreloadCleanupRepositories(),
            offlineTransactionsSyncInteractor: PreloadUnusedSync(), keychainStore: fixture.storage,
            userDefaultsStore: defaults, businessDataContext: context)
        try await cleaner.resetBusinessData()
        await gate.release()
        do {
            _ = try await pending.value
            XCTFail("Discarded writes cannot recreate data for the retained participant")
        } catch is CancellationError { }
        let records = try await fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(records.isEmpty)
        XCTAssertEqual((fixture.storage.get(.user) as UserModel?)?.id, "fixture-buyer")
    }

}

final class ResetOfflineProfile: ProfileRemoteRepository {
    func fetchProfile() async throws -> UserModel { throw RestClient.RestError.connectionLost }
    func checkGadgetExists(_ identifier: String) async throws -> Bool { throw CancellationError() }
    func changePassword(currentPassword: String, newPassword: String) async throws { throw CancellationError() }
    func deleteProfile() async throws { throw CancellationError() }
    func addGadget(gadget: UserModel.GadgetModel) async throws { throw CancellationError() }
    func changeGadget(newGadget: UserModel.GadgetModel, oldGadget: UserModel.GadgetModel) async throws { throw CancellationError() }
}

private actor ResetObservedPreload: DataFetcherInteractor {
    let preload: DataFetcherInteractorImpl
    let finished: XCTestExpectation
    init(preload: DataFetcherInteractorImpl, finished: XCTestExpectation) { self.preload = preload; self.finished = finished }
    func fetchRemoteData() async { await preload.fetchRemoteData(); finished.fulfill() }
    func loadCacheData() async { await preload.loadCacheData() }
    func prepareCatalogues() async { await preload.prepareCatalogues() }
    func startCataloguePreparation() async { await preload.startCataloguePreparation() }
    func cancelCataloguePreparation() async { await preload.cancelCataloguePreparation() }
}

final class ResetTokenRegistry: TokenRegistryService {
    var fcmUpdates: [String?] = []
    var onUpdate: (() -> Void)?
    func registerTokens() { XCTFail("Logout must not register tokens") }
    func updateDeviceToken(_ token: String) { XCTFail("Unexpected device-token update") }
    func updateFCMToken(_ token: String?) { fcmUpdates.append(token); onUpdate?() }
}
