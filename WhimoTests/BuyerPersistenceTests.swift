//
//  BuyerPersistenceTests.swift
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
import CoreLocation
import FactoryKit
import DatabaseKit
import GRDB
import RestClient
import StorageKit
import Targets
import Utility
@testable import Whimo

@MainActor
final class BuyerPersistenceTests: XCTestCase {
    func testSavedBalanceListSupportsOfflineSaleAfterRestartAndRevalidatesConfirmedVolume() async throws {
        for newerVolume in [Double?.none, 7] {
            AppContainer.shared.manager.push()
            defer { AppContainer.shared.manager.pop() }
            let fixture = try BuyerPersistenceFixture()
            defer { fixture.storage.clear() }
            let state = FilterAppStateTestDouble()
            let target = BalanceTargetDouble()
            let seasonTarget = PreloadCatalogueTarget()
            let commodities = CommodityCachingRepositoryImpl(
                localRepo: CommodityLocalRepositoryImpl(database: fixture.database, commoditiesGroupsMapper: CommoditiesGroupsMapper()),
                remoteRepo: CommodityRemoteRepositoryImpl(commoditiesTarget: seasonTarget, commoditiesGroupsMapper: CommoditiesGroupsMapper()),
                accountId: { "fixture-buyer" })
            _ = try await commodities.fetchCommodityGroups()
            let catalogue = SeasonCatalogueRepositoryImpl(groupsTarget: seasonTarget, seasonsTarget: seasonTarget,
                database: fixture.database, mapper: SeasonCatalogueMapper(), accountId: { "fixture-buyer" })
            _ = try await catalogue.seasons(commodityId: "beans")
            let mapper = SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper())
            let online = SeasonalBalanceRepositoryImpl(target: target, database: fixture.database,
                mapper: mapper, accountId: { "fixture-buyer" })
            try await target.returnBalance(volume: 10, commodityId: "beans", seasonId: "beans-past", partial: true)
            let list = BalanceListInteractorImpl(appState: state, repository: online)
            await list.refresh(cacheOnly: false)
            XCTAssertEqual(state.balance.value.list.value?.first?.volume, 10)
            XCTAssertEqual(state.balance.value.pagination?.nextPage, 2)
            await target.goOffline()
            await seasonTarget.goOffline()

            let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
            let balance = SeasonalBalanceRepositoryImpl(target: target, database: reopened, mapper: mapper, accountId: { "fixture-buyer" })
            let creation = CreationSeasonInteractorImpl(
                catalogue: SeasonCatalogueRepositoryImpl(groupsTarget: seasonTarget, seasonsTarget: seasonTarget,
                    database: reopened, mapper: SeasonCatalogueMapper(), accountId: { "fixture-buyer" }), balances: balance)
            state.createTransaction[\.commodityType] = BuyerVolumeTests.commodity
            AppContainer.shared.appState.register { state }.scope(.unique)
            AppContainer.shared.creationSeasonInteractor.register { creation }.scope(.unique)
            let volume = CommodityVolumeModule.ViewModel(volumeAmount: "10", commodityType: BuyerVolumeTests.commodity,
                transactionType: .downstream(action: .sell, recipient: .empty))
            await volume.loadSeasons()
            volume.selectSeason(try XCTUnwrap(volume.seasons.first { $0.id == "beans-past" }))
            await volume.loadBalance()
            XCTAssertTrue(volume.canConfirm)
            XCTAssertEqual(volume.seasonalBalance?.volume, 10)
            XCTAssertEqual(volume.seasonalBalance?.isCached, true)
            volume.didTapConfirm()
            XCTAssertEqual(state.createTransaction.value.confirmedBalance?.balance.volume, 10)
            if let newerVolume {
                try await target.returnBalance(volume: newerVolume, commodityId: "beans", seasonId: "beans-past")
                await list.refresh(cacheOnly: false)
                await target.goOffline()
            }
            let transactionTarget = BuyerTransactionTarget()
            let local = try fixture.reopenedLocal()
            let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: transactionTarget, transactionsMapper: fixture.mapper,
                supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
            let transactions = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
                transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
                transactionsLocalRepository: local, creationSeasonInteractor: creation)
            do {
                try await transactions.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
                    commodityType: BuyerVolumeTests.commodity, volume: state.createTransaction.value.volumeAmount, action: .sell,
                    recipient: .init(recipientID: "recipient", email: "", phone: ""),
                    seasonSelection: state.createTransaction.value.seasonSelection)
                XCTAssertNil(newerVolume)
            } catch SeasonalSaleError.insufficientBalance {
                XCTAssertEqual(newerVolume, 7)
            }
            let queued = try await fixture.reopenedLocal().fetchOnDiskTransactions()
            XCTAssertEqual(queued.count, newerVolume == nil ? 1 : 0)
            XCTAssertEqual(queued.first?.harvestSeasonId, newerVolume == nil ? "beans-past" : nil)
            XCTAssertEqual(queued.first?.volume, newerVolume == nil ? 10 : nil)
            let requests = await transactionTarget.requests
            XCTAssertEqual(requests.count, newerVolume == nil ? 1 : 0)
        }
    }

    func testFinalSellerSubmissionRejectsPastShortageBeforeSendingOrQueuing() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let local = fixture.local()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let past = HarvestSeason(id: "captured", name: "Cocoa", startDate: fixture.season.startDate,
            endDate: fixture.season.endDate, status: .past)
        let interactor = TransactionsInteractorImpl(appState: FilterAppStateTestDouble(), transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local,
            creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: BuyerCapturedCatalogue(season: past), balances: SellerFixedBalance()))
        do {
            try await interactor.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
                commodityType: BuyerVolumeTests.commodity, volume: "300", action: .sell,
                recipient: .init(recipientID: "fixture-buyer", email: "", phone: ""),
                seasonSelection: .init(commodityId: "beans", season: fixture.season))
            XCTFail("Final submission must reload status and balance, even for a previously confirmed Active season")
        } catch { }
        let requests = await target.requests
        XCTAssertTrue(requests.isEmpty)
        let queued = try await local.fetchOnDiskTransactions()
        XCTAssertTrue(queued.isEmpty)
    }

    func testSellerFinalStatusQuantityAndBalanceMatrix() async throws {
        for status in [HarvestSeasonStatus.active, .past, .archive] {
            for available in [Double(60), 0, nil] {
                let fixture = try BuyerPersistenceFixture()
                defer { fixture.storage.clear() }
                let target = BuyerTransactionTarget()
                await target.goOnline()
                let local = fixture.local()
                let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
                    supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
                let season = HarvestSeason(id: "captured", name: "Cocoa", startDate: fixture.season.startDate,
                    endDate: fixture.season.endDate, status: status)
                let interactor = TransactionsInteractorImpl(appState: FilterAppStateTestDouble(), transactionsRemoteRepository: remote,
                    transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
                    transactionsLocalRepository: local,
                    creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: BuyerCapturedCatalogue(season: season),
                        balances: SellerFixedBalance(volume: available)))
                var expectedCount = 0
                for volume in ["59", "60", "61", "nan", "-1", ""] {
                    let allowed = ["59", "60", "61"].contains(volume)
                        && (available == nil || status == .active || (available == 60 && volume != "61"))
                    do {
                        try await interactor.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
                            commodityType: BuyerVolumeTests.commodity, volume: volume, action: .sell,
                            recipient: .init(recipientID: "fixture-recipient", email: "", phone: ""),
                            seasonSelection: .init(commodityId: "beans", season: fixture.season))
                        XCTAssertTrue(allowed, "Unexpected sale: \(status), \(String(describing: available)), \(volume)")
                        expectedCount += 1
                    } catch {
                        XCTAssertFalse(allowed, "Unexpected rejection: \(error)")
                    }
                    let requests = await target.requests
                    XCTAssertEqual(requests.count, expectedCount)
                    if allowed {
                        XCTAssertEqual(requests.last?.transactionData.volume, volume)
                        XCTAssertEqual(requests.last?.transactionData.harvestSeasonId, "captured")
                        XCTAssertEqual(requests.last?.transactionData.action, .sell)
                    }
                }
            }
        }
    }

    func testOnlineBuyerValidatesCoverageAndSendsOneFullVolumeRequest() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BuyerTransactionTarget()
        await target.goOnline()
        let local = fixture.local()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: [])
        let interactor = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local,
            creationSeasonInteractor: CreationSeasonInteractorImpl(catalogue: BuyerCapturedCatalogue(season: fixture.season), balances: BuyerUnusedBalance()))
        let commodity = CommodityGroupModel.Commodity(id: "beans", code: "1801", name: "Cocoa", unit: "kg", balance: 0,
            hasRecipe: false, group: .init(id: "cocoa", name: "Cocoa"))
        do {
            try await interactor.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
                commodityType: commodity, volume: "300", action: .buy,
                recipient: .init(recipientID: "fixture-supplier", email: "", phone: ""),
                seasonSelection: .init(commodityId: "butter", season: fixture.season))
            XCTFail("A stale commodity pair must not submit")
        } catch CreationSeasonError.invalidSelection { }
        let before = await target.requests
        XCTAssertTrue(before.isEmpty)
        try await interactor.createDownstreamTransaction(farmLocation: nil, transactionCoordinates: nil,
            commodityType: commodity, volume: "300", action: .buy,
            recipient: .init(recipientID: "fixture-supplier", email: "", phone: ""),
            seasonSelection: .init(commodityId: "beans", season: fixture.season))
        let requests = await target.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.transactionData.volume, "300")
        XCTAssertEqual(requests.first?.transactionData.harvestSeasonId, "captured")
        XCTAssertEqual(state.transactions.value.list.value?.first?.harvestSeasonId, "captured")
    }

    func testConnectionLossRestartAndPastSeasonUploadPreserveOneRequestAndEvidence() async throws {
        try await exerciseOfflineCreation(action: .buy)
    }

    func testSellerConnectionLossRestartAndPastSeasonUploadPreserveOneSaleAndEvidence() async throws {
        try await exerciseOfflineCreation(action: .sell)
    }

    func testConfirmedUploadRetriesLocalReplacementAfterDatabaseFailureAndRestart() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
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
        state.transactions[\.list] = .loaded(value: [queued])
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: local,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        do {
            try await sync.syncTransactions()
            XCTFail("Local replacement must fail after the server confirms creation")
        } catch { }
        let remaining = try await local.fetchOnDiskTransactions()
        XCTAssertEqual(remaining.map(\.id), [queued.id])
        try await fixture.database.save { db in try db.execute(sql: "DROP TRIGGER fail_queue_replace") }
        let reopened = try fixture.reopenedLocal()
        let restarted = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: reopened,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        let receiptDirectory = URL(fileURLWithPath: fixture.databasePath + "-evidence/.upload-receipts")
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: receiptDirectory.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: receiptDirectory.path) }
        do {
            try await restarted.syncTransactions()
            XCTFail("Unreadable receipt storage must not authorize another create")
        } catch { }
        let requestsAfterUnreadableReceipt = await target.requests
        XCTAssertEqual(requestsAfterUnreadableReceipt.count, 1)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: receiptDirectory.path)
        await target.goOffline()
        do {
            try await restarted.syncTransactions()
            XCTFail("A failed receipt lookup must preserve the confirmed identity")
        } catch RestClient.RestError.connectionLost { }
        XCTAssertEqual(try reopened.confirmedUploadID(for: queued), "remote-buyer")
        await target.goOnline()
        try await restarted.syncTransactions()
        let requests = await target.requests
        XCTAssertEqual(requests.count, 1, "A confirmed server result must be reconciled without recreating it")
        XCTAssertNil(try reopened.confirmedUploadID(for: queued))
        let finalQueue = try await reopened.fetchOnDiskTransactions()
        XCTAssertTrue(finalQueue.isEmpty)
        let result = try await reopened.fetchTransaction(by: "remote-buyer")
        XCTAssertEqual(result.harvestSeasonId, "captured")
    }

    func testMixedQueuePartialSuccessRestartKeepsEachRequestResultAndEvidenceTogether() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let local = fixture.local()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        try await local.save(fixture.mapper.toDomain(from: seed.data))
        var expected: [String: TransactionModel] = [:]
        for index in 1...4 {
            let season = HarvestSeason(id: "captured-\(index)", name: "Season \(index)",
                startDate: fixture.season.startDate, endDate: fixture.season.endDate, status: .active)
            let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try Data("evidence-\(index)".utf8).write(to: source)
            let file = RequestModels.CreateTransaction.UploadFile(fileURL: source,
                fileName: "evidence-\(index).geojson", mimeType: "application/geo+json")
            let queued: TransactionModel
            if index <= 2 {
                queued = try await local.saveDownstreamTransaction(commodityId: "beans", volume: "\(index)", location: .file,
                    uploadFile: file, farmCoordinates: nil, transactionCoordinates: nil,
                    action: index == 1 ? .buy : .sell, recipient: .name("recipient-\(index)"), season: season)
            } else {
                queued = try await local.saveProducerTransaction(commodityId: "beans", location: .file,
                    uploadFile: file, farmCoordinates: nil, transactionCoordinates: nil, volume: "\(index)",
                    inviteRecipient: .email("producer-\(index)@example.invalid"), isBuyingFromFarmer: index == 3, season: season)
            }
            expected[season.id] = queued
            try FileManager.default.removeItem(at: source)
        }
        let target = BuyerTransactionTarget(mixedQueue: true)
        await target.goOnline()
        let restored = try fixture.reopenedLocal()
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: try await restored.fetchOnDiskTransactions())
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: restored,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        do {
            try await sync.syncTransactions()
            XCTFail("The second upload must fail after one committed success")
        } catch RestClient.RestError.connectionLost { }
        let firstAttempts = await target.mixedAttempts
        XCTAssertEqual(firstAttempts.count, 2)
        let successfulSeason = try XCTUnwrap(firstAttempts.first)
        let failedSeason = try XCTUnwrap(firstAttempts.last)
        let remaining = try await restored.fetchOnDiskTransactions()
        XCTAssertEqual(remaining.count, 3)
        XCTAssertFalse(remaining.contains { $0.harvestSeasonId == successfulSeason })
        XCTAssertTrue(state.transactions.value.updatingList.isEmpty)
        for row in remaining {
            let original = try XCTUnwrap(expected[try XCTUnwrap(row.harvestSeasonId)])
            XCTAssertEqual(row, original)
            let file = try XCTUnwrap(row.persistingData.farmLocationFile)
            XCTAssertEqual(try Data(contentsOf: file.fileURL), Data("evidence-\(Int(row.volume))".utf8))
        }
        // Recreate both repository and sync actor; the target models the same server after reconnect.
        let reopened = try fixture.reopenedLocal()
        let restarted = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: reopened,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        try await restarted.syncTransactions()
        try await restarted.syncTransactions()
        let attempts = await target.mixedAttempts
        XCTAssertEqual(attempts.count, 5)
        XCTAssertEqual(attempts.filter { $0 == successfulSeason }.count, 1)
        XCTAssertEqual(attempts.filter { $0 == failedSeason }.count, 2)
        let pending = try await reopened.fetchOnDiskTransactions()
        XCTAssertTrue(pending.isEmpty)
        for index in 1...4 {
            let uploaded = try await reopened.fetchTransaction(by: "remote-captured-\(index)")
            XCTAssertEqual(uploaded.harvestSeasonId, "captured-\(index)")
            XCTAssertEqual(uploaded.harvestSeason?.status, .past)
            XCTAssertEqual(uploaded.volume, Double(index))
            XCTAssertEqual(uploaded.type, index <= 2 ? .downstream : .producer)
        }
        let downstream = await target.requests
        for request in downstream {
            let index = Int(try XCTUnwrap(Double(request.transactionData.volume)))
            XCTAssertEqual(request.transactionData.harvestSeasonId, "captured-\(index)")
            XCTAssertEqual(request.transactionData.recipient.name, "recipient-\(index)")
            XCTAssertEqual(request.transactionData.action, index == 1 ? .buy : .sell)
        }
        let producers = await target.producerRequests
        for request in producers {
            let index = Int(try XCTUnwrap(Double(request.transactionData.volume)))
            XCTAssertEqual(request.transactionData.harvestSeasonId, "captured-\(index)")
            XCTAssertEqual(request.transactionData.recipient?.email, "producer-\(index)@example.invalid")
            XCTAssertEqual(request.transactionData.isBuyingFromFarmer, index == 3)
        }
        let evidence = await target.mixedEvidence
        for index in 1...4 { XCTAssertEqual(evidence["captured-\(index)"], Data("evidence-\(index)".utf8)) }
    }

    private func exerciseOfflineCreation(action: TransactionModel.Action) async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        let target = BuyerTransactionTarget()
        let remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: fixture.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        let repository = TransactionsCachingRepositoryImpl(localRepo: fixture.local(), remoteRepo: remote)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let seed = try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(BuyerTransactionTarget.response.utf8))
        try await fixture.local().save(fixture.mapper.toDomain(from: seed.data))
        let source = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".geojson")
        let evidence = Data("{\"type\":\"FeatureCollection\",\"features\":[]}".utf8)
        try evidence.write(to: source)
        let queued = try await repository.createDownstreamTransaction(commodityId: "beans", location: .file,
            uploadFile: .init(fileURL: source, fileName: "evidence.geojson", mimeType: "application/geo+json"),
            farmCoordinates: .init(latitude: 0, longitude: 0), transactionCoordinates: nil,
            volume: "300", action: action, recipient: .name("fixture-supplier"), season: fixture.season)
        XCTAssertEqual(queued.harvestSeasonId, "captured")
        XCTAssertEqual(queued.harvestSeason?.status, .active)
        try FileManager.default.removeItem(at: source)
        let restored = try fixture.reopenedLocal()
        let pending = try await restored.fetchOnDiskTransactions()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(action == .buy ? pending.first?.seller?.username : pending.first?.buyer?.username, "fixture-supplier")
        XCTAssertEqual(pending.first?.action, action)
        XCTAssertEqual(pending.first?.volume, 300)
        XCTAssertEqual(pending.first?.persistingData.farmLocationFile?.fileName, "evidence.geojson")
        let persistedFile = try XCTUnwrap(pending.first?.persistingData.farmLocationFile?.fileURL)
        XCTAssertNotEqual(persistedFile, source)
        XCTAssertEqual(try Data(contentsOf: persistedFile), evidence)
        let state = FilterAppStateTestDouble()
        state.transactions[\.list] = .loaded(value: pending)
        let sync = OfflineTransactionsSyncInteractorImpl(appState: state, transactionsLocalRepository: restored,
            transactionsOfflineMapper: TransactionsOfflineMapper(), transactionsTarget: target, transactionsMapper: fixture.mapper)
        do {
            try await sync.syncTransactions()
            XCTFail("Offline upload must fail and remain retryable")
        } catch RestClient.RestError.connectionLost { }
        XCTAssertTrue(state.transactions.value.updatingList.isEmpty)
        XCTAssertEqual(state.transactions.value.list.value?.first?.persistingData.state, .onDisk)
        await target.goOnline()
        try await sync.syncTransactions()
        try await sync.syncTransactions()
        let requests = await target.requests
        XCTAssertEqual(requests.count, 3) // initial fallback, failed sync, one successful upload
        for request in requests {
            XCTAssertEqual(request.transactionData.harvestSeasonId, "captured")
            XCTAssertEqual(Double(request.transactionData.volume), 300)
            XCTAssertEqual(request.transactionData.action, action == .buy ? .buy : .sell)
        }
        let last = try XCTUnwrap(requests.last)
        XCTAssertEqual(last.transactionData.commodityId, "beans")
        XCTAssertEqual(last.transactionData.recipient.name, "fixture-supplier")
        let uploadedEvidence = await target.uploadedEvidence
        XCTAssertEqual(uploadedEvidence, evidence)
        XCTAssertEqual(last.uploadFile?.mimeType, "application/geo+json")
        let remaining = try await restored.fetchOnDiskTransactions()
        XCTAssertTrue(remaining.isEmpty)
        let uploaded = try await restored.fetchTransaction(by: "remote-buyer")
        XCTAssertEqual(uploaded.harvestSeasonId, "captured")
        XCTAssertEqual(uploaded.harvestSeason?.status, .past)
    }
}

struct BuyerPersistenceFixture {
    let databasePath = NSTemporaryDirectory() + "buyer-test-" + UUID().uuidString + ".sqlite"
    let database: DatabaseImpl
    let storage: AnyStorage<KeychainStore>
    let keychainService = "buyer-test-" + UUID().uuidString
    let mapper = TransactionsMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper(),
                                    seasonMapper: SeasonCatalogueMapper())
    let season = HarvestSeason(id: "captured", name: "Cocoa 2025/26", startDate: Date(timeIntervalSince1970: 1_756_684_800),
        endDate: Date(timeIntervalSince1970: 1_788_220_800), status: .active)

    init() throws {
        database = try DatabaseImpl(writer: DatabaseQueue(path: databasePath))
        storage = AnyStorage(state: KeychainStore(bundleIdentifier: keychainService))
        storage.set(UserModel(id: "fixture-buyer", username: "Fixture buyer", gadgets: []), key: .user)
    }

    func local() -> TransactionsLocalRepositoryImpl { makeLocal(database) }

    func reopenedLocal() throws -> TransactionsLocalRepositoryImpl {
        makeLocal(try DatabaseImpl(writer: DatabaseQueue(path: databasePath)))
    }

    private func makeLocal(_ database: DatabaseImpl) -> TransactionsLocalRepositoryImpl {
        TransactionsLocalRepositoryImpl(database: database, commoditiesGroupsMapper: CommoditiesGroupsMapper(),
            transactionsMapper: mapper, transactionsOfflineMapper: TransactionsOfflineMapper(), userMapper: UserMapper(),
            userOfflineMapper: UserOfflineMapper(), keychainStore: storage,
            fileStorage: FileStorageService(queueDirectory: URL(fileURLWithPath: databasePath + "-evidence")))
    }
}

actor BuyerTransactionTarget: TransactionsTarget {
    var requests: [RequestModels.CreateTransaction.Downstream] = []
    var producerRequests: [RequestModels.CreateTransaction.Producer] = []
    private var offline = true
    private let mixedQueue: Bool
    var mixedAttempts: [String] = []
    var mixedEvidence: [String: Data] = [:]
    init(mixedQueue: Bool = false) { self.mixedQueue = mixedQueue }
    private func mixedResponse(seasonId: String?, commodityId: String, volume: String, producer: Bool,
                               file: RequestModels.CreateTransaction.UploadFile?) throws -> ResponseModels.TransactionInfo {
        let seasonId = try XCTUnwrap(seasonId)
        mixedAttempts.append(seasonId)
        if let file { mixedEvidence[seasonId] = try Data(contentsOf: file.fileURL) }
        if mixedAttempts.count == 2 { throw RestClient.RestError.connectionLost }
        var json = Self.response.replacingOccurrences(of: "remote-buyer", with: "remote-" + seasonId)
            .replacingOccurrences(of: "\"captured\"", with: "\"" + seasonId + "\"")
            .replacingOccurrences(of: "\"volume\":300", with: "\"volume\":" + volume)
            .replacingOccurrences(of: "\"id\":\"beans\"", with: "\"id\":\"" + commodityId + "\"")
        if producer { json = json.replacingOccurrences(of: "downstream", with: "producer") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(json.utf8))
    }
    private var createEntered: XCTestExpectation?
    private var createContinuation: CheckedContinuation<Void, Never>?
    func pauseNextCreate(entered: XCTestExpectation) { createEntered = entered }
    func resumeCreate() { createContinuation?.resume(); createContinuation = nil }
    var uploadedEvidence: Data?
    func goOnline() { offline = false }
    func goOffline() { offline = true }
    func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo {
        requests.append(model)
        if let entered = createEntered {
            createEntered = nil
            await withCheckedContinuation { continuation in
                createContinuation = continuation
                entered.fulfill()
            }
        }
        if offline { throw RestClient.RestError.connectionLost }
        if mixedQueue {
            return try mixedResponse(seasonId: model.transactionData.harvestSeasonId, commodityId: model.transactionData.commodityId,
                volume: model.transactionData.volume, producer: false, file: model.uploadFile)
        }
        if let file = model.uploadFile { uploadedEvidence = try Data(contentsOf: file.fileURL) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(Self.response.utf8))
    }
    static let response = """
    {"data":{"id":"remote-buyer", "created_at":"2026-09-08T00:00:00Z", "type":"downstream",
    "status":"pending", "action":"buying", "volume":300,
    "is_buying_from_farmer":false, "is_automatic":false,
    "buyer":{"id":"fixture-buyer", "username":"Fixture buyer", "gadgets":[]},
    "commodity":{"id":"beans", "code":"1801", "name":"Cocoa", "unit":"kg", "group":{"id":"cocoa", "name":"Cocoa"}},
    "harvest_season":{"id":"captured", "name":"Cocoa 2025/26", "start_date":"2025-09-01", "end_date":"2026-09-01", "status":"past"}}}
    """
    func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo {
        throw CocoaError(.featureUnsupported)
    }
    func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo {
        if offline { throw RestClient.RestError.connectionLost }
        XCTAssertEqual(model.transactionId, "remote-buyer")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(Self.response.utf8))
    }
    func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo {
        throw CocoaError(.featureUnsupported)
    }
    func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo {
        throw CocoaError(.featureUnsupported)
    }
    func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo {
        producerRequests.append(model)
        if offline { throw RestClient.RestError.connectionLost }
        if mixedQueue {
            return try mixedResponse(seasonId: model.transactionData.harvestSeasonId, commodityId: model.transactionData.commodityId,
                volume: model.transactionData.volume, producer: true, file: model.uploadFile)
        }
        if let file = model.uploadFile { uploadedEvidence = try Data(contentsOf: file.fileURL) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = Self.response.replacingOccurrences(of: "downstream", with: "producer")
            .replacingOccurrences(of: "pending", with: "accepted")
        return try decoder.decode(ResponseModels.TransactionInfo.self, from: Data(response.utf8))
    }
    func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws -> ResponseModels.UpdateTransactionStatus {
        throw CocoaError(.featureUnsupported)
    }
    func updateTransactionGeodata(_ model: RequestModels.UpdateTransactionGeodata) async throws {
        throw CocoaError(.featureUnsupported)
    }
    func downloadGeojson(_ model: RequestModels.DownloadGeojson) async throws -> ResponseModels.DownloadGeojson {
        throw CocoaError(.featureUnsupported)
    }
    func downloadCSV(_ model: RequestModels.DownloadCSV) async throws -> ResponseModels.DownloadCSV {
        throw CocoaError(.featureUnsupported)
    }
    func downloadBundle(_ model: RequestModels.DownloadBundle) async throws -> ResponseModels.DownloadBundle {
        throw CocoaError(.featureUnsupported)
    }
    func requestTransactionGeodata(_ model: RequestModels.RequestTransactionGeodata) async throws -> ResponseModels.RequestTransactionGeodata {
        throw CocoaError(.featureUnsupported)
    }
    func resendTransactionNotification(_ model: RequestModels.ResendTransactionNotification) async throws -> ResponseModels.ResendTransactionNotification {
        throw CocoaError(.featureUnsupported)
    }
}

private struct BuyerCapturedCatalogue: SeasonCatalogueRepository {
    let season: HarvestSeason
    func cachedSeasons(commodityId: String) async throws -> [HarvestSeason] { [season] }
    func groups() async throws -> CatalogueResult<CatalogueGroup> { throw CreationSeasonError.invalidSelection }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> { throw CreationSeasonError.invalidSelection }
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> { .init(values: [season], isCached: false) }
}

private struct BuyerUnusedBalance: SeasonalBalanceRepository {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        XCTFail("A buyer request must never validate against own balance")
        throw SeasonalBalanceError.unavailableCache
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage { throw SeasonalBalanceError.unavailableCache }
}

private struct SellerFixedBalance: SeasonalBalanceRepository {
    var volume: Double? = 60
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        guard let volume else { throw SeasonalBalanceError.incompleteResponse }
        return .init(volume: volume, traceability: nil, isCached: true)
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
}
