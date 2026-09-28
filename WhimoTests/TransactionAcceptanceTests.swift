//
//  TransactionSeasonTests.swift
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
import Combine
import SwiftUI
import FactoryKit
import Resources
@testable import CommonUI
import RestClient
import Targets
import Utility
import StorageKit
@testable import Whimo

@MainActor
final class TransactionAcceptanceTests: XCTestCase {
    func testConditionalDetailsCachePreservesNewerSnapshotAndConfirmedStatus() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        try await fixture.local.save(fixture.pending)
        fixture.target.seasonStatus = "past"
        let past = fixture.storage.mapper.toDomain(from: try fixture.target.decodeTransaction(status: "pending"))
        fixture.target.seasonStatus = "archived"
        let archived = fixture.storage.mapper.toDomain(from: try fixture.target.decodeTransaction(status: "pending"))
        try await fixture.local.saveRefreshedDetails(archived, replacing: fixture.pending)
        try await fixture.local.saveRefreshedDetails(past, replacing: fixture.pending)
        let newest = try await fixture.local.fetchTransaction(by: "ordinary")
        XCTAssertEqual(newest.harvestSeason?.status, .archive)
        let accepted = fixture.storage.mapper.toDomain(from: try fixture.target.decodeTransaction(status: "accepted"))
        try await fixture.local.saveStatusOutcome([accepted])
        try await fixture.local.saveRefreshedDetails(past, replacing: archived)
        let reopened = try fixture.storage.reopenedLocal()
        let confirmed = try await reopened.fetchTransaction(by: "ordinary")
        XCTAssertEqual(confirmed.status, .accepted)
        XCTAssertEqual(confirmed.harvestSeason?.status, .archive)
        let queued = try await reopened.fetchOnDiskTransactions()
        XCTAssertTrue(queued.isEmpty)
    }

    func testPastShortagePreventsStatusSubmission() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        try await fixture.local.save(fixture.pending)
        let balances = AcceptanceBalanceRepository()
        let balance = BalanceListInteractorImpl(appState: fixture.state, repository: balances)
        fixture.registerContext()
        AppContainer.shared.appState.register { [state = fixture.state] in state }.scope(.unique)
        AppContainer.shared.transactionsInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { [local = fixture.local] in local }.scope(.unique)
        AppContainer.shared.transactionsRemoteRepository.register { [remote = fixture.remote] in remote }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { [state = fixture.state] in
            TransactionListInteractorImpl(appState: state, repository: AcceptanceListRepository())
        }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { balance }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        let viewModel = TransactionDetailsModule.ViewModel(transactionId: "ordinary")
        await viewModel.onAppear()
        await viewModel.didTapAcceptTransaction()
        XCTAssertTrue(fixture.target.requests.isEmpty)
        XCTAssertEqual(viewModel.transaction.value?.status, .pending)
    }

    func testStatusEncodingContainsOnlyAcceptedOrRejected() throws {
        for (status, expected) in [(RequestModels.UpdateTransactionStatus.Status.accept, "accepted"), (.reject, "rejected")] {
            let request = RequestModels.UpdateTransactionStatus(transactionId: "stored", status: status)
            let data = try JSONEncoder().encode(request)
            XCTAssertEqual(try JSONSerialization.jsonObject(with: data) as? [String: String], ["status": expected])
        }
    }

    func testReturnedAutomaticAndOrdinaryPersistInTheirStoredSeason() async throws {
        let fixture = try AcceptanceFixture(automatic: true)
        defer { fixture.storage.storage.clear() }
        let outcome = try await fixture.interactor.updateTransaction(fixture.pending, status: .accept)
        XCTAssertEqual(outcome.transaction.status, .accepted)
        XCTAssertEqual(outcome.automaticTransaction?.volume, 7)
        XCTAssertEqual(outcome.automaticTransaction?.status, .automatic)
        XCTAssertFalse(outcome.cacheSaveFailed)
        let reopened = try fixture.storage.reopenedLocal()
        let ordinary = try await reopened.fetchTransaction(by: "ordinary")
        let automatic = try await reopened.fetchTransaction(by: "automatic")
        XCTAssertEqual(ordinary.harvestSeasonId, "stored-season")
        XCTAssertEqual(automatic.harvestSeasonId, "stored-season")
        XCTAssertEqual(ordinary.status, .accepted)
        XCTAssertEqual(automatic.volume, 7)
    }

    func testCacheFailureRetainsConfirmedResultAndRollsBackTheWholePair() async throws {
        let fixture = try AcceptanceFixture(automatic: true)
        defer { fixture.storage.storage.clear() }
        try await fixture.local.save(fixture.pending)
        try await fixture.storage.database.save { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_automatic BEFORE INSERT ON `transaction` WHEN NEW.id = 'automatic'
                BEGIN SELECT RAISE(ABORT, 'fixture'); END
                """)
        }
        let outcome = try await fixture.interactor.updateTransaction(fixture.pending, status: .accept)
        XCTAssertEqual(outcome.transaction.status, .accepted)
        XCTAssertTrue(outcome.cacheSaveFailed)
        XCTAssertEqual(fixture.state.transactions.value.list.value?[id: "ordinary"]?.status, .accepted)
        let stored = try await fixture.local.fetchTransaction(by: "ordinary")
        XCTAssertEqual(stored.status, .pending, "Both returned records must commit atomically")
    }

    func testConflictLeavesPendingAndAllowsReplenishmentRetryOrReject() async throws {
        for seasonStatus in ["past", "archived"] {
            for retryStatus in [TransactionModel.StatusChange.accept, .reject] {
                let fixture = try AcceptanceFixture(seasonStatus: seasonStatus)
                defer { fixture.storage.storage.clear() }
                try await fixture.local.save(fixture.pending)
                fixture.target.conflict = true
                do {
                    _ = try await fixture.interactor.updateTransaction(fixture.pending, status: .accept)
                    XCTFail("Conflict cannot claim acceptance")
                } catch {
                    guard case TransactionModel.StatusChangeError.conflict = error else { return XCTFail("Expected safe domain conflict") }

                }
                let pending = try await fixture.local.fetchTransaction(by: "ordinary")
                XCTAssertEqual(pending.status, .pending)
                XCTAssertEqual(fixture.state.transactions.value.list.value?[id: "ordinary"]?.status, .pending)
                fixture.target.conflict = false
                let result = try await fixture.interactor.updateTransaction(pending, status: retryStatus)
                XCTAssertEqual(result.transaction.status, retryStatus == .accept ? .accepted : .rejected)
                XCTAssertEqual(result.transaction.harvestSeasonId, "stored-season")
                XCTAssertEqual(fixture.target.requests.count, 2)
            }
        }
    }

    func testChangedSeasonOrIncompleteOutcomeCannotOverwritePending() async throws {
        let fixture = try AcceptanceFixture(automatic: true)
        defer { fixture.storage.storage.clear() }
        try await fixture.local.save(fixture.pending)
        for invalid in ["changed-season", "missing-automatic", "wrong-status", "invalid-automatic-amount"] {
            fixture.target.invalid = invalid
            do {
                _ = try await fixture.interactor.updateTransaction(fixture.pending, status: .accept)
                XCTFail("Invalid status response must not claim success")
            } catch { }
            let pending = try await fixture.local.fetchTransaction(by: "ordinary")
            XCTAssertEqual(pending.status, .pending)
            XCTAssertEqual(pending.harvestSeasonId, "stored-season")
        }
    }

    func testDetailsSuppressesDuplicateAndRetainsSuccessAfterRefreshFailure() async throws {
        try await verifyDetailsOutcome(automatic: true)
    }

    func testDetailsShowsOrdinarySuccessWhenPreviewedAdjustmentWasNotNeeded() async throws {
        try await verifyDetailsOutcome(automatic: false)
    }

    private func verifyDetailsOutcome(automatic: Bool) async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = try AcceptanceFixture(automatic: automatic)
        defer { fixture.storage.storage.clear() }
        try await fixture.local.save(fixture.pending)
        let transactions = AcceptanceListRepository()
        let balances = AcceptanceBalanceRepository()
        balances.volume = 2
        let alerts = AlertManager()
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        let list = TransactionListInteractorImpl(appState: fixture.state, repository: transactions)
        let balance = BalanceListInteractorImpl(appState: fixture.state, repository: balances)
        list.setQuery(.init(search: "Cocoa", action: .sell, filter: .init(group: .init(id: "cocoa", name: "Cocoa"))))
        balance.setQuery(.init(search: "coffee", filter: .init(group: .init(id: "coffee", name: "Coffee"))))
        let transactionQuery = list.query
        let balanceQuery = balance.query
        fixture.registerContext()
        AppContainer.shared.appState.register { [state = fixture.state] in state }.scope(.unique)
        AppContainer.shared.transactionsInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { [local = fixture.local] in local }.scope(.unique)
        AppContainer.shared.transactionsRemoteRepository.register { [remote = fixture.remote] in remote }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { list }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { balance }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { AcceptanceProfile() }.scope(.unique)
        let viewModel = TransactionDetailsModule.ViewModel(transactionId: "ordinary")
        let loaded = expectation(description: "Exact balance loaded")
        let observation = viewModel.$isLoadingAcceptanceBalance.combineLatest(viewModel.$acceptanceBalance)
            .filter { !$0.0 && $0.1 != nil }.first().sink { _ in loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 5)
        observation.cancel()
        XCTAssertEqual(viewModel.acceptanceAutomaticPreview?.quantity, 10)
        let reads = balances.exactQueries.count
        XCTAssertEqual(viewModel.transaction.value?.status, .pending)
        fixture.target.statusRequested = expectation(description: "Status suspended")
        let first = Task { await viewModel.didTapAcceptTransaction() }
        await fulfillment(of: [try XCTUnwrap(fixture.target.statusRequested)], timeout: 5)
        await viewModel.didTapAcceptTransaction()
        await viewModel.didTapRejectTransaction()
        fixture.target.statusSuspension?.resume()
        await first.value
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertEqual(viewModel.transaction.value?.status, .accepted)
        XCTAssertEqual(viewModel.transaction.value?.harvestSeasonId, "stored-season")
        XCTAssertEqual(viewModel.statusOutcome?.automaticTransaction?.volume, automatic ? 7 : nil)
        XCTAssertEqual(balances.exactQueries.count, reads)
        XCTAssertNil(viewModel.acceptanceAutomaticPreview)
        XCTAssertEqual(alerts.models.last?.subtitle, automatic
            ? AppLocale.TransactionAcceptance.automatic("7", "kg") : AppLocale.TransactionAcceptance.accepted)
        let stored = try await fixture.local.fetchTransaction(by: "ordinary")
        XCTAssertEqual(stored.status, .accepted)
        if automatic {
            let storedAutomatic = try await fixture.local.fetchTransaction(by: "automatic")
            XCTAssertEqual(storedAutomatic.volume, 7)
        }
        XCTAssertTrue(viewModel.hasStatusRefreshError)
        XCTAssertFalse(viewModel.isSubmittingStatus)
        XCTAssertFalse(viewModel.waitingRecipientResponse)
        XCTAssertEqual(list.query, transactionQuery)
        XCTAssertEqual(balance.query, balanceQuery)
        XCTAssertEqual(transactions.queries, [transactionQuery])
        XCTAssertEqual(balances.queries, [balanceQuery])
        fixture.state.transactions.dispatch { $0.list = .loaded(value: [fixture.pending]) }
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        XCTAssertEqual(viewModel.transaction.value?.status, .accepted)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let refreshedJSON = fixture.target.transactionJSON(status: "accepted")
            .replacingOccurrences(of: "\"type\":\"downstream\"", with: "\"updated_at\":\"2026-09-08T01:00:00Z\",\"type\":\"downstream\"")
        let refreshed = fixture.storage.mapper.toDomain(from: try decoder.decode(ResponseModels.Transaction.self, from: Data(refreshedJSON.utf8)))
        fixture.state.transactions.dispatch { $0.list = .loaded(value: [refreshed]) }
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        XCTAssertEqual(viewModel.transaction.value?.updatedAt, "2026-09-08T01:00:00Z")
    }
}

@MainActor
struct AcceptanceFixture {
    let storage: BuyerPersistenceFixture
    let local: TransactionsLocalRepositoryImpl
    let remote: TransactionsRemoteRepositoryImpl
    let target: AcceptanceTarget
    let state = FilterAppStateTestDouble()
    let context: BusinessDataContext
    let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "acceptance-mode-" + UUID().uuidString))
    let mode: BusinessModeRepositoryImpl
    let interactor: TransactionsInteractorImpl
    var pending: TransactionModel

    init(seasonStatus: String = "active", automatic: Bool = false, context: BusinessDataContext = .init()) throws {
        self.context = context
        storage = try BuyerPersistenceFixture()
        mode = BusinessModeRepositoryImpl(store: defaults, environment: "acceptance-fixture")
        local = storage.local()
        target = AcceptanceTarget(seasonStatus: seasonStatus, automatic: automatic)
        remote = TransactionsRemoteRepositoryImpl(transactionsTarget: target, transactionsMapper: storage.mapper,
            supplierTransactionMapper: SupplierTransactionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper(), userMapper: UserMapper()))
        interactor = TransactionsInteractorImpl(appState: state, transactionsRemoteRepository: remote,
            transactionsCachingRepository: TransactionsCachingRepositoryImpl(localRepo: local, remoteRepo: remote),
            transactionsLocalRepository: local,
            creationSeasonInteractor: AcceptanceCreationSeasons(), businessDataContext: context)
        pending = storage.mapper.toDomain(from: try target.decodeTransaction(status: "pending"))
        state.transactions.dispatch { $0.list = .loaded(value: [pending]) }
    }

    func makeDetails(balances: AcceptanceBalanceRepository, profile: AcceptanceProfile = AcceptanceProfile(),
                     savePending: Bool = true) async throws -> TransactionDetailsModule.ViewModel {
        registerContext()
        if savePending { try await local.save(pending) }
        AppContainer.shared.appState.register { [state] in state }.scope(.unique)
        AppContainer.shared.transactionsInteractor.register { [interactor] in interactor }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { [local] in local }.scope(.unique)
        AppContainer.shared.transactionsRemoteRepository.register { [remote] in remote }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { [state] in
            TransactionListInteractorImpl(appState: state, repository: AcceptanceListRepository())
        }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { [state] in
            BalanceListInteractorImpl(appState: state, repository: balances)
        }.scope(.unique)
        AppContainer.shared.profileLocalRepository.register { profile }.scope(.unique)
        return TransactionDetailsModule.ViewModel(transactionId: "ordinary")
    }

    func registerContext() {
        AppContainer.shared.businessDataContext.register { [context] in context }.scope(.unique)
        AppContainer.shared.businessModeInteractor.register { [mode, state] in
            BusinessModeInteractorImpl(repository: mode, cleaner: PreloadUnusedCleaner(), appState: state)
        }.scope(.unique)
    }

}

@MainActor
final class AcceptanceTarget: TransactionsTarget {
    var requests: [RequestModels.UpdateTransactionStatus] = []
    var conflict = false
    var fetchError: Error?
    var fetchRequested: XCTestExpectation?
    var fetchSuspension: CheckedContinuation<ResponseModels.TransactionInfo, Error>?
    var fetchCount = 0
    var fetchStatus = "pending"
    var statusError: Error?
    var statusRequested: XCTestExpectation?
    var statusSuspension: CheckedContinuation<Void, Never>?
    var buyerRecipient = false
    var missingSeason = false
    var requestedVolume: Double = 12
    var unit = "kg"
    var seasonName = "Cocoa 2025/26"
    var invalid: String?
    var seasonStatus: String
    let automatic: Bool
    init(seasonStatus: String, automatic: Bool) { self.seasonStatus = seasonStatus; self.automatic = automatic }

    func transactionJSON(status: String, automatic: Bool = false) -> String {
        var json = """
        {"id":"\(automatic ? "automatic" : "ordinary")", "created_at":"2026-09-08T00:00:00Z", "type":"downstream",
        "status":"\(status)", "action":"selling", "volume":\(automatic ? 7 : requestedVolume),
        "is_buying_from_farmer":false, "is_automatic":\(automatic), "created_by_id":"buyer",
        "seller":{"id":"seller", "username":"Fixture seller", "gadgets":[]},
        "buyer":{"id":"buyer", "username":"Fixture buyer", "gadgets":[]},
        "commodity":{"id":"beans", "code":"1801", "name":"Cocoa", "unit":"\(unit)", "group":{"id":"cocoa", "name":"Cocoa"}},
        "harvest_season":{"id":"stored-season", "name":"\(seasonName)", "start_date":"2025-09-01",
        "end_date":"2026-09-01", "status":"\(seasonStatus)"}}
        """
        if buyerRecipient { json = json.replacingOccurrences(of: "\"created_by_id\":\"buyer\"", with: "\"created_by_id\":\"seller\"") }
        if missingSeason {
            let expression = try? NSRegularExpression(pattern: "\"harvest_season\":\\{[^}]+\\}")
            json = expression?.stringByReplacingMatches(in: json, range: NSRange(json.startIndex..., in: json), withTemplate: "\"harvest_season\":null") ?? json
        }
        return json
    }
    func decodeTransaction(status: String) throws -> ResponseModels.Transaction {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.Transaction.self, from: Data(transactionJSON(status: status).utf8))
    }
    func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws -> ResponseModels.UpdateTransactionStatus {
        requests.append(model)
        if let statusRequested {
            await withCheckedContinuation { continuation in
                statusSuspension = continuation
                statusRequested.fulfill()
            }
        }
        if let statusError { throw statusError }
        if conflict { throw RestClient.RestError.clientError(message: "private balance must not be displayed", statusCode: .conflict, serverErrorCode: nil) }
        let ordinary = transactionJSON(status: invalid == "wrong-status" ? "pending" : model.status.rawValue)
        let extra = automatic ? transactionJSON(status: "accepted", automatic: true) : "null"
        var json = "{\"data\":{\"transaction\":\(ordinary),\"automatic_transaction\":\(extra)}}"
        if invalid == "invalid-automatic-amount" { json = json.replacingOccurrences(of: "\"volume\":7", with: "\"volume\":\"invalid\"") }
        if invalid == "changed-season" { json = json.replacingOccurrences(of: "stored-season", with: "different-season") }
        if invalid == "missing-automatic" { json = "{\"data\":{\"transaction\":\(ordinary)}}" }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.UpdateTransactionStatus.self, from: Data(json.utf8))
    }
    func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo {
        fetchCount += 1
        if let fetchRequested {
            return try await withCheckedThrowingContinuation { continuation in
                fetchSuspension = continuation
                fetchRequested.fulfill()
            }
        }
        if let fetchError { throw fetchError }
        return .init(data: try decodeTransaction(status: fetchStatus))
    }
    func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo {
        throw CocoaError(.featureUnsupported)
    }
    func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo {
        throw CocoaError(.featureUnsupported)
    }
    func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo {
        throw CocoaError(.featureUnsupported)
    }
    func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo {
        throw CocoaError(.featureUnsupported)
    }
    func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo {
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

final class AcceptanceProfile: ProfileLocalRepository {
    var participantId = "seller"
    func fetchProfile() throws -> UserModel { .init(id: participantId, username: "Fixture seller", gadgets: []) }
    func save(_ model: UserModel) { }
    func flush() { }
}

final class AcceptanceListRepository: TransactionListRepository {
    var queries: [TransactionListQuery] = []
    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        queries.append(query)
        throw CocoaError(.fileReadUnknown)
    }
}

@MainActor
final class AcceptanceBalanceRepository: SeasonalBalanceRepository {
    var queries: [BalanceListQuery] = []
    var exactQueries: [(String, String)] = []
    var volume: Double = 5
    var isCached = false
    var savedVolume: Double?
    var savedRequested: XCTestExpectation?
    var savedSuspension: CheckedContinuation<SeasonalBalancePage, Error>?
    var error: Error?
    var requested: XCTestExpectation?
    var suspension: CheckedContinuation<ExactSeasonalBalance, Error>?
    var suspend = false

    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        if query.commodityId != nil {
            if let savedRequested {
                return try await withCheckedThrowingContinuation { continuation in
                    savedSuspension = continuation
                    savedRequested.fulfill()
                }
            }
            guard let savedVolume else { throw SeasonalBalanceError.unavailableCache }

            let row = SeasonalBalance(id: "saved", volume: savedVolume,
                commodity: .init(id: query.commodityId ?? "", code: "1801", name: "Cocoa", unit: "kg", group: .init(id: "cocoa", name: "Cocoa")),
                season: .init(id: query.exactSeasonId ?? "",
                    startDate: .distantPast, endDate: .distantFuture, status: .past), traceability: nil, hasRecipe: false)
            return .init(rows: [row], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1),
                message: nil, success: true, isCached: true)
        }
        queries.append(query)
        throw CocoaError(.fileReadUnknown)
    }
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        exactQueries.append((commodityId, seasonId))
        if suspend {
            return try await withCheckedThrowingContinuation { continuation in
                suspension = continuation
                requested?.fulfill()
            }
        }
        requested?.fulfill()
        if let error { throw error }
        return .init(volume: volume, traceability: nil, isCached: isCached)
    }
}

private struct AcceptanceCreationSeasons: CreationSeasonInteractor {
    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> { throw CreationSeasonError.catalogueRequired }
    func validate(_ selection: CreationSeason?, commodityId: String) async throws -> HarvestSeason { throw CreationSeasonError.catalogueRequired }
    func balance(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance { throw CreationSeasonError.catalogueRequired }
}
