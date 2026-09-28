//
//  ProducerCreationTests.swift
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
import FactoryKit
import DatabaseKit
import GRDB
import StorageKit
import Targets
import RestClient
@testable import Whimo

@MainActor
final class ProducerCreationTests: XCTestCase {
    func testInitialFormShowsCommodityActiveWithoutChangingSubmissionInputs() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.creationSeasonInteractor.register {
            CreationSeasonInteractorImpl(catalogue: ProducerCommodityCatalogue(), balances: ProducerUnusedBalance())
        }.scope(.unique)
        for seller in [TransactionType.Seller.farmer(isCurrentlyOnFarm: true), .cooperative(recipient: nil)] {
            state.createTransaction.dispatch {
                $0.commodityType = BuyerVolumeTests.commodity
                $0.volumeAmount = "750"
            }
            let form = CreateTransactionFormModule.ViewModel(transactionType: .producer(seller: seller))
            let draft = state.createTransaction.value
            await form.refreshProducerSeason()
            XCTAssertEqual(form.volumeSeason?.id, "beans-active")
            XCTAssertEqual(form.volumeSeason?.status, .active)
            XCTAssertEqual(form.volumeAmount, "750")
            XCTAssertTrue(form.isSaveButtonEnabled)
            XCTAssertNil(form.volumeBreakdown)
            XCTAssertTrue(draft.hasSameSubmissionInputs(as: state.createTransaction.value))
        }
    }

    func testInitialFormIgnoresCancelledOrReplacedCommoditySeasonResponse() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        for cancel in [true, false] {
            let state = FilterAppStateTestDouble()
            let started = expectation(description: "Producer season requested")
            let seasons = ProducerDeferredSeasons(started: started)
            AppContainer.shared.appState.register { state }.scope(.unique)
            AppContainer.shared.creationSeasonInteractor.register { seasons }.scope(.unique)
            state.createTransaction.dispatch {
                $0.commodityType = BuyerVolumeTests.commodity
                $0.volumeAmount = "750"
            }
            let form = CreateTransactionFormModule.ViewModel(transactionType: .producer(seller: .cooperative(recipient: nil)))
            let refresh = Task { await form.refreshProducerSeason() }
            await fulfillment(of: [started], timeout: 2)
            if cancel {
                refresh.cancel()
            } else {
                state.createTransaction[\.commodityType] = .initialState
                state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
            }
            await seasons.complete()
            await refresh.value
            XCTAssertNil(form.volumeSeason)
            XCTAssertNil(state.createTransaction.value.seasonSelection)
        }
    }

    func testBothProducersEncodeActiveForCurrentCommodityWithoutSelection() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let local = fixture.local()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let catalogue = ProducerCommodityCatalogue()
        let interactor = TransactionsInteractorImpl(appState: FilterAppStateTestDouble(), transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local,
            creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: catalogue, balances: ProducerUnusedBalance()))
        for farmer in [true, false] {
            for commodityId in ["beans", "butter", "beans"] {
                let commodity = CommodityGroupModel.Commodity(id: commodityId, code: "1801", name: "Cocoa", unit: "kg", balance: 0,
                    hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
                try await interactor.createProducerTransaction(farmLocation: nil, commodityType: commodity, volume: "300",
                    isBuyingFromFarmer: farmer, transactionCoordinates: nil, inviteRecipient: nil)
                let requests = await target.producerRequests
                let request = try XCTUnwrap(requests.last)
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(request.transactionData)) as? [String: Any])
                XCTAssertEqual(payload["harvest_season_id"] as? String, commodityId == "beans" ? "beans-active" : "butter-active")
                XCTAssertEqual(payload["commodity_id"] as? String, commodityId)
                XCTAssertEqual(payload["volume"] as? String, "300")
                XCTAssertEqual(payload["is_buying_from_farmer"] as? Bool, farmer)
            }
        }
        let sent = await target.producerRequests
        XCTAssertEqual(sent.count, 6)
    }

    func testProducerReopenAndPastSeasonUploadPreserveSourceRecipientAndEvidence() async throws {
        for farmer in [true, false] {
            let fixture = try BuyerPersistenceFixture()
            defer { fixture.storage.clear() }
            let target = BuyerTransactionTarget()
            let local = fixture.local()
            let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
                supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
            try await local.save(fixture.mapper.toDomain(from: seed.data))
            let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".geojson")
            let evidence = Data("{\"type\":\"FeatureCollection\",\"features\":[]}".utf8)
            try evidence.write(to: source)
            let file = FileObject(id: "evidence.geojson", url: source, creationDate: .now,
                fileType: .typeRegular, size: NSNumber(value: evidence.count), childs: [])
            let state = FilterAppStateTestDouble()
            state.transactions[\.list] = .loaded(value: [])
            let interactor = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
                transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
                transactionsLocalRepository: local,
                creationSeasonInteractor: CreationSeasonInteractorImpl(
                    catalogue: ProducerCatalogue(values: [fixture.season]), balances: ProducerUnusedBalance()))
            let recipient = TransactionType.Recipient(recipientID: "", email: "cooperative@example.invalid", phone: "")
            try await interactor.createProducerTransaction(
                farmLocation: .fileManager(file: file, coordinates: .init(latitude: 0, longitude: 0)),
                commodityType: BuyerVolumeTests.commodity, volume: "300", isBuyingFromFarmer: farmer,
                transactionCoordinates: .init(latitude: 1, longitude: 2), inviteRecipient: farmer ? nil : recipient)
            try FileManager.default.removeItem(at: source)
            let restored = try fixture.reopenedLocal()
            let pending = try await restored.fetchOnDiskTransactions()
            let queued = try XCTUnwrap(pending.first)
            XCTAssertEqual(pending.count, 1)
            XCTAssertEqual(queued.type, .producer)
            XCTAssertEqual(queued.status, .recorded)
            XCTAssertEqual(queued.isBuyingFromFarmer, farmer)
            XCTAssertEqual(queued.harvestSeasonId, "captured")
            XCTAssertEqual(queued.harvestSeason?.status, .active)
            XCTAssertEqual(queued.volume, 300)
            XCTAssertEqual(queued.farmLatitude, 0)
            XCTAssertEqual(queued.transactionLongitude, 2)
            let queuedFile = try XCTUnwrap(queued.persistingData.farmLocationFile)
            XCTAssertNotEqual(queuedFile.fileURL, source)
            XCTAssertEqual(try Data(contentsOf: queuedFile.fileURL), evidence)
            state.transactions[\.list] = .loaded(value: pending)
            let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: restored,
                transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
            do {
                try await sync.syncTransactions()
                XCTFail("Offline upload must retain its retryable record")
            } catch RestClient.RestError.connectionLost { }
            XCTAssertEqual(state.transactions.value.list.value?.first?.persistingData.state, .onDisk)
            // The response reports the captured season as Past. Upload has no catalogue dependency or re-resolution.
            await target.goOnline()
            try await sync.syncTransactions()
            try await sync.syncTransactions()
            let requests = await target.producerRequests
            XCTAssertEqual(requests.count, 3)
            for request in requests {
                XCTAssertEqual(request.transactionData.harvestSeasonId, "captured")
                XCTAssertEqual(request.transactionData.isBuyingFromFarmer, farmer)
                XCTAssertEqual(request.transactionData.recipient?.email, farmer ? nil : "cooperative@example.invalid")
                XCTAssertEqual(request.transactionData.location, .file)
                XCTAssertEqual(Double(request.transactionData.volume), 300)
                XCTAssertEqual(request.uploadFile?.fileName, "evidence.geojson")
            }
            let uploaded = await target.uploadedEvidence
            XCTAssertEqual(uploaded, evidence)
            let remaining = try await restored.fetchOnDiskTransactions()
            XCTAssertTrue(remaining.isEmpty)
            let synced = try await restored.fetchTransaction(by: "remote-buyer")
            XCTAssertEqual(synced.harvestSeasonId, "captured")
            XCTAssertEqual(synced.harvestSeason?.status, .past)
        }
    }

    func testSeasonlessLegacyProducerRemainsIntactBesideNewQueuedProducer() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let local = fixture.local()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        let model = fixture.mapper.toDomain(from: seed.data)
        try await local.save(model)
        var legacy = fixture.mapper.toDatabase(from: model)
        legacy.id = "legacy-producer"
        legacy.type = .producer(inviteRecipient: .phone("+12025550123"))
        legacy.status = .recorded
        legacy.harvestSeasonId = nil
        legacy.harvestSeason = nil
        legacy.persistingData = .onDisk(farmLocationFile: .init(fileURL: URL(fileURLWithPath: "/tmp/legacy.geojson"),
            fileName: "legacy.geojson", mimeType: "application/geo+json"))
        try await fixture.database.save(legacy)
        _ = try await local.saveProducerTransaction(commodityId: "beans", location: nil, uploadFile: nil,
            farmCoordinates: nil, transactionCoordinates: nil, volume: "300", inviteRecipient: nil,
            isBuyingFromFarmer: true, season: fixture.season)
        let restored = try fixture.reopenedLocal()
        let before = try await restored.fetchTransaction(by: "legacy-producer")
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let sync = OfflineTransactionsSyncInteractorImpl(appState: FilterAppStateTestDouble(), transactionsLocalRepository: restored,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        try await sync.syncTransactions()
        let requests = await target.producerRequests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.transactionData.harvestSeasonId, "captured")
        let remaining = try await restored.fetchOnDiskTransactions()
        XCTAssertEqual(remaining.map(\.id), ["legacy-producer"])
        XCTAssertEqual(remaining.first, before)
        XCTAssertEqual(remaining.first?.producerRecipient, .phone("+12025550123"))
    }

    func testProducerCreationUsesCommodityCatalogueAfterOfflineDatabaseReopen() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let catalogueTarget = CatalogueTargetDouble()
        let online = SeasonCatalogueRepositoryImpl(groupsTarget: catalogueTarget, seasonsTarget: catalogueTarget,
            database: fixture.database, mapper: SeasonCatalogueMapper(), accountId: { "fixture" })
        _ = try await online.seasons(commodityId: "beans")
        let storage = AnyStorage(state: UserDefaultsStore(suiteName: "producer-catalogue-" + UUID().uuidString))
        defer { storage.clear() }
        let client = RestClient(baseURL: try XCTUnwrap(URL(string: "https://catalogue.invalid")),
            connectivity: CatalogueOfflineConnectivity(), userDefaults: storage)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let offline = SeasonCatalogueRepositoryImpl(groupsTarget: catalogueTarget, seasonsTarget: RestHarvestSeasonsTarget(restClient: client),
            database: reopened, mapper: SeasonCatalogueMapper(), accountId: { "fixture" })
        let local = try fixture.reopenedLocal()
        let target = BuyerTransactionTarget()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        try await local.save(fixture.mapper.toDomain(from: seed.data))
        let interactor = TransactionsInteractorImpl(appState: FilterAppStateTestDouble(), transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local,
            creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: offline, balances: ProducerUnusedBalance()))
        for farmer in [true, false] {
            try await interactor.createProducerTransaction(farmLocation: .gps(coordinates: .init(latitude: 0, longitude: 0)),
                commodityType: BuyerVolumeTests.commodity, volume: "300", isBuyingFromFarmer: farmer,
                transactionCoordinates: nil, inviteRecipient: farmer ? nil : .init(recipientID: "", email: "", phone: "+12025550123"))
        }
        let pending = try await local.fetchOnDiskTransactions()
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { $0.harvestSeasonId == "active-a" && $0.location == .gps && $0.farmLatitude == 0 })
        let cooperative = try XCTUnwrap(pending.first(where: { !$0.isBuyingFromFarmer }))
        let request: RequestModels.CreateTransaction.Producer = TransactionsOfflineMapper().toDTO(from: cooperative)
        XCTAssertEqual(request.transactionData.recipient?.phone, "+12025550123")
        let unknown = CommodityGroupModel.Commodity(id: "uncached", code: "1801", name: "Cocoa", unit: "kg", balance: 0,
            hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
        do {
            try await interactor.createProducerTransaction(farmLocation: nil, commodityType: unknown, volume: "300",
                isBuyingFromFarmer: false, transactionCoordinates: nil, inviteRecipient: nil)
            XCTFail("Cached beans or group seasons cannot cover a newly selected commodity")
        } catch CreationSeasonError.catalogueRequired { }
        let requests = await target.producerRequests
        XCTAssertEqual(requests.count, 2)
    }

    func testMissingActiveBlocksProducerBeforeTransportOrQueue() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let local = fixture.local()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let past = HarvestSeason(id: "past", name: "Past", startDate: fixture.season.startDate,
            endDate: fixture.season.endDate, status: .past)
        let archived = HarvestSeason(id: "archived", name: "Archived", startDate: fixture.season.startDate,
            endDate: fixture.season.endDate, status: .archive)
        let noId = HarvestSeason(id: "", name: "Invalid", startDate: fixture.season.startDate,
            endDate: fixture.season.endDate, status: .active)
        for values in [[], [past, archived], [noId], [fixture.season, fixture.season]] {
            let interactor = TransactionsInteractorImpl(appState: FilterAppStateTestDouble(), transactionsRemoteRepository: remote,
                transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
                transactionsLocalRepository: local,
                creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: ProducerCatalogue(values: values), balances: ProducerUnusedBalance()))
            do {
                try await interactor.createProducerTransaction(farmLocation: nil, commodityType: BuyerVolumeTests.commodity,
                    volume: "300", isBuyingFromFarmer: true, transactionCoordinates: nil, inviteRecipient: nil)
                XCTFail("A new producer record must wait for commodity Active, never rely on the server default")
            } catch CreationSeasonError.catalogueRequired { }
        }
        let sent = await target.producerRequests
        XCTAssertTrue(sent.isEmpty)
        let queued = try await local.fetchOnDiskTransactions()
        XCTAssertTrue(queued.isEmpty)
    }
}

private actor ProducerDeferredSeasons: CreationSeasonInteractor {
    let started: XCTestExpectation
    private var continuation: CheckedContinuation<CatalogueResult<HarvestSeason>, Error>?

    init(started: XCTestExpectation) { self.started = started }

    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        try await withCheckedThrowingContinuation {
            continuation = $0
            started.fulfill()
        }
    }

    func complete() {
        continuation?.resume(returning: .init(values: [
            .init(id: "active", name: "Active", startDate: .distantPast, endDate: .distantFuture, status: .active)
        ], isCached: true))
        continuation = nil
    }

    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason {
        throw CreationSeasonError.invalidSelection
    }

    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        throw SeasonalBalanceError.unavailableCache
    }
}

private struct ProducerCatalogue: SeasonCatalogueRepository {
    let values: [HarvestSeason]
    func cachedSeasons(commodityId: String) async throws -> [HarvestSeason] {
        try await seasons(commodityId: commodityId).values
    }
    func groups() async throws -> CatalogueResult<CatalogueGroup> { throw CreationSeasonError.invalidSelection }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> { throw CreationSeasonError.invalidSelection }
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> { .init(values: values, isCached: true) }
}

private struct ProducerUnusedBalance: SeasonalBalanceRepository {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        XCTFail("Producer creation has no own-balance guard")
        throw SeasonalBalanceError.unavailableCache
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
}

private struct ProducerCommodityCatalogue: SeasonCatalogueRepository {
    func cachedSeasons(commodityId: String) async throws -> [HarvestSeason] {
        try await seasons(commodityId: commodityId).values
    }
    func groups() async throws -> CatalogueResult<CatalogueGroup> { throw CreationSeasonError.invalidSelection }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> { throw CreationSeasonError.invalidSelection }
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        // Both commodities share a group but have different Active seasons. Dates deliberately lie in the past.
        .init(values: [
            .init(id: commodityId + "-past", name: "Past", startDate: .distantPast, endDate: .distantFuture, status: .past),
            .init(id: commodityId + "-active", name: "Active", startDate: .distantPast, endDate: .init(timeIntervalSince1970: 0), status: .active)
        ], isCached: true)
    }
}
