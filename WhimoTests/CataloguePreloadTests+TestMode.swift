//
//  CataloguePreloadTests+TestMode.swift
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
import Targets
@testable import CommonUI
import SwiftUI
import Resources
import Utility
@testable import Whimo

extension CataloguePreloadTests {
    @MainActor
    func testSettingsOfflineModeRoundTripPreservesSessionAndResetsLogout() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "settings-mode-" + UUID().uuidString))
        defer { defaults.clear() }
        defaults.set(true, key: .isLoggedIn)
        let state = FilterAppStateTestDouble()
        let context = BusinessDataContext()
        let mode = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        let unused = PreloadCleanupRepositories()
        let cleaner = DataCleanerInteractorImpl(appState: state,
            dataFetcherInteractor: makePreload(database: fixture.database, target: PreloadCatalogueTarget()),
            database: fixture.database,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence")),
            authRepository: unused, offlineTransactionsSyncInteractor: PreloadUnusedSync(), keychainStore: fixture.storage,
            userDefaultsStore: defaults, businessDataContext: context, businessModeRepository: mode)
        let transition = BusinessModeInteractorImpl(repository: mode, cleaner: cleaner, appState: state)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
        let alerts = AlertManager()
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        let settings = SettingsModule.ViewModel()
        let indicator = RootTestModeViewModel()
        XCTAssertEqual(indicator.visibleRouteIndices, [])
        XCTAssertFalse(settings.isTestMode)
        await settings.setTestModeEnabled(true)
        XCTAssertFalse(settings.isTestMode, "Opening the explanation is not consent")
        await settings.confirmTestModeEntry()
        XCTAssertTrue(settings.isTestMode)
        let entered = expectation(description: "Root shows the active Test mode")
        let enteredSubscription = indicator.$visibleRouteIndices.filter { $0 == [0] }.prefix(1).sink { _ in entered.fulfill() }
        await fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(state.system.value.selectedTab, .settings)
        XCTAssertEqual(state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(BusinessModeRepositoryImpl(store: defaults, environment: "debug").mode, .test)
        XCTAssertEqual(BusinessModeRepositoryImpl(store: defaults, environment: "stage").mode, .ordinary)
        XCTAssertEqual(try ProfileLocalRepositoryImpl(keychainStore: fixture.storage, userMapper: UserMapper()).fetchProfile().id, "fixture-buyer")
        XCTAssertFalse(settings.isRowEnabled(.accountInfo))
        XCTAssertTrue(settings.isRowEnabled(.language))
        await settings.setTestModeEnabled(false)
        let exited = expectation(description: "Root hides the indicator on exit")
        let exitedSubscription = indicator.$visibleRouteIndices.filter { $0.isEmpty }.prefix(1).sink { _ in exited.fulfill() }
        await fulfillment(of: [exited], timeout: 3)
        withExtendedLifetime((enteredSubscription, exitedSubscription)) { }
        XCTAssertFalse(settings.isTestMode)
        XCTAssertTrue(settings.isRowEnabled(.accountInfo))
        await settings.setTestModeEnabled(true)
        await settings.confirmTestModeEntry()
        try await cleaner.dropAll()
        XCTAssertEqual(mode.mode, .ordinary)
    }

    func testSettingsBlocksHiddenQueueAndRechecksNewWorkAfterExplanation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.preload.prepareCatalogues()
        await scenario.settings.setTestModeEnabled(true)
        XCTAssertEqual(scenario.settings.entryAlert, .explanation)
        scenario.settings.cancelTestModeEntry()
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        let groups = try await makeCommodities(database: scenario.fixture.database, target: scenario.catalogue).fetchCommodityGroups()
        XCTAssertFalse(groups.isEmpty, "Cancel preserves business catalogues")
        await scenario.settings.setTestModeEnabled(true)
        try await scenario.createQueued()
        let queued = try await scenario.fixture.local().fetchOnDiskTransactions()
        XCTAssertEqual(queued.count, 1)
        scenario.state.transactions[\.list] = .loaded(value: [])
        await scenario.settings.confirmTestModeEntry()
        XCTAssertEqual(scenario.settings.entryAlert, .synchronizationRequired)
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        let retained = try await scenario.fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertEqual(retained.map(\.id), queued.map(\.id))
        scenario.settings.cancelTestModeEntry()
        await scenario.settings.setTestModeEnabled(true)
        XCTAssertEqual(scenario.settings.entryAlert, .synchronizationRequired)
        await scenario.target.goOnline()
        try await scenario.sync.syncTransactions()
        XCTAssertFalse(scenario.settings.isTestMode, "Sync completion does not consent to entry")
        scenario.settings.cancelTestModeEntry()
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        XCTAssertTrue(scenario.settings.isTestMode)
    }

    func testSettingsBlocksUnfinishedSendBeforeItHasAQueueRecord() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.preload.prepareCatalogues()
        await scenario.target.goOnline()
        let entered = expectation(description: "Send awaiting response")
        await scenario.target.pauseNextCreate(entered: entered)
        let send = Task { try await scenario.createQueued() }
        await fulfillment(of: [entered], timeout: 3)
        let queue = try await scenario.fixture.local().fetchOnDiskTransactions()
        XCTAssertTrue(queue.isEmpty)
        await scenario.settings.setTestModeEnabled(true)
        XCTAssertEqual(scenario.settings.entryAlert, .synchronizationRequired)
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        await scenario.target.resumeCreate()
        try await send.value
        scenario.settings.cancelTestModeEntry()
        await scenario.settings.setTestModeEnabled(true)
        XCTAssertEqual(scenario.settings.entryAlert, .explanation)
    }

    func testSettingsExitDiscardsTestEvidenceAndDelayedUploadAcrossRestart() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        await scenario.preload.prepareCatalogues()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".geojson")
        try Data("test-evidence".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        try await scenario.createQueued(evidence: source)
        let queued = try await scenario.fixture.local().fetchOnDiskTransactions()
        let transaction = try XCTUnwrap(queued.first)
        let evidence = try XCTUnwrap(transaction.persistingData.farmLocationFile?.fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: evidence.path))
        await scenario.target.goOnline()
        let entered = expectation(description: "Test upload response delayed")
        await scenario.target.pauseNextCreate(entered: entered)
        let upload = Task { try await scenario.sync.syncTransactions() }
        await fulfillment(of: [entered], timeout: 3)
        scenario.state.createTransaction[\.volumeAmount] = "old draft"
        scenario.state.navigation[\.path].append(.push(.accountInfo))
        await scenario.settings.setTestModeEnabled(false)
        XCTAssertNil(scenario.settings.entryAlert)
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        XCTAssertEqual(scenario.state.system.value.selectedTab, .settings)
        XCTAssertEqual(scenario.state.createTransaction.value.volumeAmount, "")
        await scenario.target.resumeCreate()
        do { try await upload.value; XCTFail("Old upload must be discarded") } catch is CancellationError { }
        let remaining = try await scenario.fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: evidence.path))
        XCTAssertNil(try scenario.files.confirmedUploadID(for: transaction.id))
        try await scenario.sync.syncTransactions()
        let requests = await scenario.target.requests
        XCTAssertEqual(requests.count, 2, "Offline attempt and test upload only")
        let reopened = BusinessModeRepositoryImpl(store: scenario.defaults, environment: "debug")
        XCTAssertEqual(reopened.mode, .ordinary)
        XCTAssertEqual(scenario.fixture.storage.get(.accessToken) as String?, "synthetic-access")
    }

    func testTestModeColdRootPreservesIdentityAndPublicLogoutResetsSelection() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let reopenedMode = BusinessModeRepositoryImpl(store: scenario.defaults, environment: "debug")
        XCTAssertEqual(reopenedMode.mode, .test)
        let reopenedTransition = BusinessModeInteractorImpl(repository: reopenedMode, cleaner: scenario.cleaner, appState: scenario.state)
        AppContainer.shared.businessModeInteractor.register { reopenedTransition }.scope(.unique)
        AppContainer.shared.businessModeRepository.register { reopenedMode }.scope(.unique)
        let indicator = RootTestModeViewModel()
        XCTAssertEqual(indicator.visibleRouteIndices, [0], "Remembered mode is visible before the first publisher delivery")
        XCTAssertTrue(SettingsModule.ViewModel().isTestMode)
        let client = AppContainer.shared.makeRestClient(baseURL: try XCTUnwrap(URL(string: "https://fixture.invalid/api/v1")),
                                                        configuration: .ephemeral)
        defer { client.sessionManager.cancelAllRequests() }
        let request = try client.request(ModeRequestRouter(path: "/transactions/", method: .get)).convertible.asURLRequest()
        XCTAssertEqual(request.url?.absoluteString, "https://fixture.invalid/api/v1/test/transactions/",
                       "Root, Settings and requests restore the same mode")
        let profile = ProfileLocalRepositoryImpl(keychainStore: scenario.fixture.storage, userMapper: UserMapper())
        AppContainer.shared.profileLocalRepository.register { profile }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { scenario.preload }.scope(.unique)
        AppContainer.shared.connectivity.register { CatalogueOfflineConnectivity() }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { scenario.sync }.scope(.unique)
        let authorized = expectation(description: "Cold offline Root retains authenticated identity")
        let subscription = scenario.state.navigation.activity.sink { if $0 == .authorized { authorized.fulfill() } }
        let root = RootModule.ViewModel()
        await fulfillment(of: [authorized], timeout: 3)
        XCTAssertEqual(scenario.state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(try profile.fetchProfile().id, "fixture-buyer")
        XCTAssertEqual(scenario.defaults.get(.currentLocalize) as String?, "fr")
        let more = MoreModule.ViewModel()
        XCTAssertFalse(more.isDeleteAccountEnabled)
        more.didTapDeleteAccount()
        AppContainer.shared.tokenRegistryService.register { ResetTokenRegistry() }.scope(.unique)
        await MoreModule.ViewModel.LogoutInteractor().logout()
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        XCTAssertEqual(BusinessModeRepositoryImpl(store: scenario.defaults, environment: "debug").mode, .ordinary)
        XCTAssertEqual(scenario.state.navigation.value.path, [.root(.login, embedInNavigationView: true)])
        withExtendedLifetime((root, subscription)) { }
    }

    func testFailedTargetModeRootPreloadKeepsSelectionIdentityAndSettings() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        let profile = ProfileLocalRepositoryImpl(keychainStore: scenario.fixture.storage, userMapper: UserMapper())
        let profileInteractor = ProfileInteractorImpl(appState: scenario.state,
            profileCachingRepository: ProfileCachingRepositoryImpl(localRepo: profile, remoteRepo: ResetOfflineProfile(),
                businessDataContext: scenario.context), profileLocalRepository: profile, businessDataContext: scenario.context)
        let failedTarget = BalanceTargetDouble()
        await failedTarget.goOffline()
        let balances = SeasonalBalanceRepositoryImpl(target: failedTarget, database: scenario.fixture.database,
            mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()), accountId: { "fixture-buyer" },
            businessDataContext: scenario.context)
        let list = BalanceListInteractorImpl(appState: scenario.state, repository: balances, businessDataContext: scenario.context)
        let unused = PreloadUnrelatedData()
        let preload = DataFetcherInteractorImpl(profileInteractor: profileInteractor, notificationsSettingsInteractor: unused,
            transactionsInteractor: unused, balanceInteractor: list, notificationsInteractor: unused, connectivity: PreloadConnectivity(),
            commodityRepository: makeCommodities(database: scenario.fixture.database, target: scenario.catalogue),
            seasonRepository: makeSeasons(database: scenario.fixture.database, target: scenario.catalogue),
            accountId: { "fixture-buyer" }, businessDataContext: scenario.context)
        let initial = expectation(description: "Initial Root preload finished")
        let switched = expectation(description: "Target-mode Root preload finished despite unavailable transport")
        let observed = ModeObservedPreload(preload: preload, initial: initial, switched: switched)
        AppContainer.shared.profileLocalRepository.register { profile }.scope(.unique)
        AppContainer.shared.dataFetcherInteractor.register { observed }.scope(.unique)
        AppContainer.shared.connectivity.register { PreloadConnectivity() }.scope(.unique)
        AppContainer.shared.userNotificationsService.register { UserNotificationsService() }.scope(.unique)
        AppContainer.shared.offlineTransactionsSyncInteractor.register { scenario.sync }.scope(.unique)
        let root = RootModule.ViewModel()
        await fulfillment(of: [initial], timeout: 3)
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        await fulfillment(of: [switched], timeout: 3)
        XCTAssertEqual(scenario.mode.mode, .test)
        XCTAssertEqual(scenario.state.system.value.selectedTab, .settings)
        XCTAssertEqual(scenario.state.navigation.value.path, [.root(.tabBar, embedInNavigationView: true)])
        XCTAssertEqual(try profile.fetchProfile().id, "fixture-buyer")
        XCTAssertEqual(scenario.fixture.storage.get(.accessToken) as String?, "synthetic-access")
        withExtendedLifetime(root) { }
    }

    func testSettingsRejectsDelayedHTTPResponseAndTestUnauthorizedDoesNotLogout() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        AppContainer.shared.connectivity.register { PreloadConnectivity() }.scope(.unique)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ModeURLProtocol.self]
        let client = AppContainer.shared.makeRestClient(baseURL: try XCTUnwrap(URL(string: "https://mode.example.invalid/api/v1")),
            configuration: configuration)
        let transport = ModeTransport()
        ModeURLProtocol.transport = transport
        defer { ModeURLProtocol.transport = nil }
        let unauthorized = ModeUnauthorizedWorker()
        client.clientErrorWorker = unauthorized
        let entered = expectation(description: "Ordinary HTTP response held")
        transport.entered = entered
        let request = Task { try await client.makeRequest(ModeRequestRouter(path: "/transactions/", method: .get)) as ModeHTTPResponse }
        await fulfillment(of: [entered], timeout: 3)
        XCTAssertEqual(transport.requests.first?.request.url?.path, "/api/v1/transactions")
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        try transport.respond(status: 401)
        do { _ = try await request.value; XCTFail("Obsolete HTTP response must be cancelled") } catch is CancellationError { }
        XCTAssertEqual(unauthorized.count, 0)
        let testEntered = expectation(description: "Test request held")
        transport.entered = testEntered
        let testRequest = Task { try await client.makeRequest(ModeRequestRouter(path: "/transactions/", method: .get)) as ModeHTTPResponse }
        await fulfillment(of: [testEntered], timeout: 3)
        XCTAssertEqual(transport.requests.last?.request.url?.path, "/api/v1/test/transactions")
        try transport.respond(status: 401)
        do { _ = try await testRequest.value; XCTFail("Unauthorized test request must report failure") } catch { }
        XCTAssertEqual(unauthorized.count, 0, "A test endpoint failure must not discard the shared session")
        XCTAssertEqual(scenario.mode.mode, .test)
        XCTAssertEqual(scenario.fixture.storage.get(.accessToken) as String?, "synthetic-access")
    }

    func testSettingsAlertConfirmationAndRepeatedInputCommitOnlyOnce() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        let manager = AppContainer.shared.alertManager.resolve()
        let displayed = expectation(description: "Confirmation presented")
        let display = manager.$models.dropFirst().filter { !$0.isEmpty }.prefix(1).sink { _ in displayed.fulfill() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.setTestModeEnabled(true)
        await fulfillment(of: [displayed], timeout: 3)
        XCTAssertEqual(manager.models.count, 1)
        let confirmed = expectation(description: "Exactly one switch committed")
        let selection = scenario.mode.changes.filter { $0 == .test }.sink { _ in confirmed.fulfill() }
        let button = try XCTUnwrap(manager.models.last?.buttons.first)
        button.action?()
        button.action?()
        manager.close()
        await fulfillment(of: [confirmed], timeout: 3)
        XCTAssertEqual(scenario.mode.mode, .test)
        withExtendedLifetime((display, selection)) { }
    }

    func testSettingsAlertActionsAndLocalizedDesigns() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        let manager = AppContainer.shared.alertManager.resolve()
        let displayed = expectation(description: "Entry alert presented")
        let subscription = manager.$models.dropFirst().filter { !$0.isEmpty }.prefix(1).sink { _ in displayed.fulfill() }
        await scenario.settings.setTestModeEnabled(true)
        await fulfillment(of: [displayed], timeout: 3)
        let alert = try XCTUnwrap(manager.models.last)
        XCTAssertEqual(alert.buttons.count, 1)
        alert.onDismiss?()
        XCTAssertNil(scenario.settings.entryAlert)
        XCTAssertFalse(scenario.settings.isTestMode)
        for locale in [Resources.LocalizeKeys.english, .french, .spanish] {
            let previous = UserDefaults.standard.string(forKey: "currentLocalize")
            UserDefaults.standard.set(locale.rawValue, forKey: "currentLocalize")
            defer { UserDefaults.standard.set(previous, forKey: "currentLocalize") }
            for blocked in [false, true] {
                let rendered = AlertView(alertModel: .init(title: AppLocale.TestMode.entryTitle,
                    contentView: AnyView(SettingsModule.EntryContent(isBlocked: blocked)),
                    buttons: [.init(title: AppLocale.TestMode.gotIt)]), actionDidTap: {})
                    .frame(width: 328).background(Color.white)
                let image = try XCTUnwrap(ImageRenderer(content: rendered).uiImage)
                let attachment = XCTAttachment(image: image)
                attachment.name = "test-mode-alert-\(locale.rawValue)-\(blocked ? "blocked" : "entry")"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let navigator = AppFlowNavigator(.constant(scenario.state.navigation.value.path))
        let appeared = expectation(description: "Settings hierarchy appeared")
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 360, height: 640))
        defer { window.isHidden = true; previousWindow?.makeKey() }
        let host = UIHostingController(rootView: SettingsModule.assemble().environmentObject(navigator)
            .onAppear { appeared.fulfill() })
        window.rootViewController = host
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 3)
        host.view.layoutIfNeeded()
        let settingsImage = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let settingsAttachment = XCTAttachment(image: settingsImage)
        settingsAttachment.name = "test-mode-settings-disabled"
        settingsAttachment.lifetime = .keepAlways
        add(settingsAttachment)
        withExtendedLifetime(subscription) { }
    }

    func testExistingClientRoutesBothModesAndKeepsSharedAuthenticationOrdinary() throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "mode-routing-" + UUID().uuidString))
        defer { defaults.clear() }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ModeURLProtocol.self]
        AppContainer.shared.userDefaultsStore.register { defaults }.scope(.unique)
        for base in ["https://whimo.krasnopolsky.dev/api/v1", "https://staging.whimo.net/api/v1", "https://whimo.net/api/v1"] {
            let mode = BusinessModeRepositoryImpl(store: defaults, environment: base)
            AppContainer.shared.businessModeRepository.register { mode }.scope(.unique)
            let client = AppContainer.shared.makeRestClient(baseURL: try XCTUnwrap(URL(string: base)), configuration: configuration)
            defer { client.sessionManager.cancelAllRequests() }
            let business = ModeRequestRouter(path: "/transactions/", method: .get)
            let ordinary = try client.request(business).convertible.asURLRequest()
            XCTAssertEqual(ordinary.url?.absoluteString, base + "/transactions/")
            mode.select(.test)
            let test = try client.request(business).convertible.asURLRequest()
            XCTAssertEqual(test.url?.absoluteString, base + "/test/transactions/")
            let acceptance = RequestRouter.Transactions.updateTransaction(.init(transactionId: "pending-fixture", status: .accept))
            let acceptanceRequest = try client.request(acceptance).convertible.asURLRequest()
            XCTAssertEqual(acceptanceRequest.url?.absoluteString, base + "/test/transactions/pending-fixture/status/")
            XCTAssertEqual(acceptanceRequest.httpMethod, "PATCH")
            for (path, method) in [("/auth/jwt/create/", ModeRequestRouter.HTTPMethod.post),
                                   ("/auth/jwt/refresh/", .post), ("/users/profile/", .get)] {
                let request = try client.request(ModeRequestRouter(path: path, method: method)).convertible.asURLRequest()
                XCTAssertEqual(request.url?.absoluteString, base + path)
            }
            mode.select(.ordinary)
            let restored = try client.request(business).convertible.asURLRequest()
            XCTAssertEqual(restored.url, ordinary.url)
        }
    }
}

private struct ModeRequestRouter: AnyNetworkRouter {
    let path: String
    let method: HTTPMethod
}

@MainActor
final class ModeScenario {
    let fixture: BuyerPersistenceFixture
    let defaults: AnyStorage<UserDefaultsStore>
    let state = FilterAppStateTestDouble()
    let context = BusinessDataContext()
    let catalogue = PreloadCatalogueTarget()
    let target = BuyerTransactionTarget()
    let files: FileStorageService
    let mode: BusinessModeRepositoryImpl
    let preload: DataFetcherInteractorImpl
    let cleaner: DataCleanerInteractorImpl
    let transactions: TransactionsInteractorImpl
    let sync: OfflineTransactionsSyncInteractorImpl
    let settings: SettingsModule.ViewModel
    let creation: CreationSeasonInteractorImpl

    init(test: CataloguePreloadTests, balances: SeasonalBalanceRepository = PreloadUnusedBalance()) throws {
        fixture = try BuyerPersistenceFixture()
        defaults = AnyStorage(state: UserDefaultsStore(suiteName: "mode-scenario-" + UUID().uuidString))
        defaults.set(true, key: .isLoggedIn)
        defaults.set("fr", key: .currentLocalize)
        fixture.storage.set("synthetic-access", key: .accessToken)
        fixture.storage.set("synthetic-refresh", key: .refreshToken)
        mode = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        files = FileStorageService(queueDirectory: URL(fileURLWithPath: fixture.databasePath + "-evidence"))
        preload = test.makePreload(database: fixture.database, target: catalogue)
        creation = CreationSeasonInteractorImpl(catalogue: test.makeSeasons(database: fixture.database, target: catalogue),
            balances: balances)
        let local = TransactionsLocalRepositoryImpl(database: fixture.database, commoditiesGroupsMapper: CommoditiesGroupsMapper(),
            transactionsMapper: fixture.mapper, transactionsOfflineMapper: TransactionsOfflineMapper(), userMapper: UserMapper(),
            userOfflineMapper: UserOfflineMapper(), keychainStore: fixture.storage, fileStorage: files, businessDataContext: context)
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()),
            businessDataContext: context)
        transactions = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote, businessDataContext: context),
            transactionsLocalRepository: local, creationSeasonInteractor: creation, businessDataContext: context)
        sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: local,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper,
            businessDataContext: context)
        cleaner = DataCleanerInteractorImpl(appState: state, dataFetcherInteractor: preload, database: fixture.database,
            fileStorage: files, authRepository: PreloadCleanupRepositories(), offlineTransactionsSyncInteractor: sync,
            keychainStore: fixture.storage, userDefaultsStore: defaults, businessDataContext: context, businessModeRepository: mode)
        let transition = BusinessModeInteractorImpl(repository: mode, cleaner: cleaner, appState: state)
        AppContainer.shared.appState.register { [state] in state }.scope(.unique)
        AppContainer.shared.businessDataContext.register { [context] in context }.scope(.unique)
        AppContainer.shared.businessModeRepository.register { [mode] in mode }.scope(.unique)
        AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
        AppContainer.shared.dataCleanerInteractor.register { [cleaner] in cleaner }.scope(.unique)
        AppContainer.shared.userDefaultsStore.register { [defaults] in defaults }.scope(.unique)
        let alerts = AlertManager()
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        settings = SettingsModule.ViewModel()
    }

    func createQueued(evidence: URL? = nil) async throws {
        let seasons = try await creation.seasons(commodityId: "beans")
        let season = try XCTUnwrap(seasons.values.first { $0.status == .active })
        let location = evidence.map { url in
            FarmLocation.fileManager(file: FileObject(id: "test.geojson", url: url, creationDate: .now,
                fileType: .typeRegular, size: 13, childs: []), coordinates: .init(latitude: 0, longitude: 0))
        }
        try await transactions.createDownstreamTransaction(farmLocation: location, transactionCoordinates: nil,
            commodityType: BuyerVolumeTests.commodity, volume: "10", action: .buy,
            recipient: .init(recipientID: "supplier", email: "", phone: ""),
            seasonSelection: .init(commodityId: "beans", season: season))
    }

    func clearStorage() {
        fixture.storage.clear()
        defaults.clear()
    }
}

private struct ModeHTTPResponse: Decodable { let value: String }

private final class ModeUnauthorizedWorker: RestClientErrorWorker {
    private let lock = NSLock()
    private var calls = 0
    var count: Int { lock.withLock { calls } }
    func unauthorized(_ path: Endpoint, method: HTTPMethod, headers: HTTPHeaders?) async {
        lock.withLock { calls += 1 }
    }
}

private final class ModeTransport {
    private let lock = NSLock()
    private var pending: [ModeURLProtocol] = []
    private var startExpectation: XCTestExpectation?
    var entered: XCTestExpectation? {
        get { lock.withLock { startExpectation } }
        set { lock.withLock { startExpectation = newValue } }
    }
    var requests: [ModeURLProtocol] { lock.withLock { pending } }
    func start(_ request: ModeURLProtocol) {
        lock.withLock { pending.append(request) }
        entered?.fulfill()
    }
    func respond(status: Int) throws {
        let request = try XCTUnwrap(requests.last)
        let url = try XCTUnwrap(request.request.url)
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]))
        request.client?.urlProtocol(request, didReceive: response, cacheStoragePolicy: .notAllowed)
        request.client?.urlProtocol(request, didLoad: Data("{\"value\":\"fixture\",\"message\":\"fixture error\"}".utf8))
        request.client?.urlProtocolDidFinishLoading(request)
    }
}

private final class ModeURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var currentTransport: ModeTransport?
    static var transport: ModeTransport? {
        get { lock.withLock { currentTransport } }
        set { lock.withLock { currentTransport = newValue } }
    }
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { Self.transport?.start(self) }
    override func stopLoading() { }
}

private actor ModeObservedPreload: DataFetcherInteractor {
    let preload: DataFetcherInteractorImpl
    let initial: XCTestExpectation
    let switched: XCTestExpectation
    private var hasPreloaded = false
    init(preload: DataFetcherInteractorImpl, initial: XCTestExpectation, switched: XCTestExpectation) {
        self.preload = preload
        self.initial = initial
        self.switched = switched
    }
    func fetchRemoteData() async {
        await preload.fetchRemoteData()
        if hasPreloaded { switched.fulfill() } else { initial.fulfill() }
        hasPreloaded = true
    }
    func loadCacheData() async { await preload.loadCacheData() }
    func prepareCatalogues() async { await preload.prepareCatalogues() }
    func startCataloguePreparation() async { await preload.startCataloguePreparation() }
    func cancelCataloguePreparation() async { await preload.cancelCataloguePreparation() }
}
