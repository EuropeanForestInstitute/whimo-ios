//
//  HomeFilterRestorationTests.swift
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

import Combine
import Contacts
import CoreLocation
import XCTest
import UserNotifications
import FactoryKit
import CommonUI
import RestClient
import Utility
@testable import Whimo

@MainActor
final class HomeFilterRestorationTests: XCTestCase {
    override func setUp() {
        super.setUp()

        AppContainer.shared.manager.push()
    }

    override func tearDown() {
        AppContainer.shared.manager.pop()
        super.tearDown()
    }

    func testRestoredDatesSurviveChipReset() async throws {
        let state = FilterAppStateTestDouble()
        let from = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_785_542_400))
        let until = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 10, to: from))
        state.transactions.dispatch {
            $0.query.search = "cocoa"
            $0.query.action = .buy
            $0.query.createdAtFrom = from
            $0.query.createdAtTo = until
            $0.query.filter = .init(group: .init(id: "cocoa", name: "Cocoa"))
        }
        let interactor = TransactionListInteractorImpl(appState: state, repository: EmptyTransactionListRepository())
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { interactor }.scope(.unique)
        AppContainer.shared.seasonCatalogueInteractor.register { EmptySeasonCatalogue() }.scope(.unique)
        AppContainer.shared.permissionsService.register { HomePermissionsServiceTestDouble() }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { HomeTransactionsLocalRepositoryTestDouble() }.scope(.unique)
        let viewModel = HomeModule.ViewModel()
        XCTAssertEqual(viewModel.dates.count, 2)
        viewModel.clearFilter()
        XCTAssertEqual(interactor.query.createdAtFrom, from)
        XCTAssertEqual(interactor.query.createdAtTo, until)
        XCTAssertEqual(interactor.query.search, "cocoa")
        XCTAssertEqual(interactor.query.action, .buy)
        XCTAssertTrue(interactor.query.filter.isEmpty)
        await viewModel.didPullRefresh()
    }
    func testPullRefreshFinishesWhenSwiftUICancelsCaller() async throws {
        let state = FilterAppStateTestDouble()
        state.transactions.dispatch { $0.list = .loaded(value: []) }
        let started = expectation(description: "Refresh reached repository")
        let repository = HomeRefreshRepository(started: started)
        let interactor = TransactionListInteractorImpl(appState: state, repository: repository)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { interactor }.scope(.unique)
        AppContainer.shared.seasonCatalogueInteractor.register { EmptySeasonCatalogue() }.scope(.unique)
        AppContainer.shared.permissionsService.register { HomePermissionsServiceTestDouble() }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { HomeTransactionsLocalRepositoryTestDouble() }.scope(.unique)
        let viewModel = HomeModule.ViewModel()
        let refresh = Task { await viewModel.didPullRefresh() }
        await fulfillment(of: [started], timeout: 2)
        refresh.cancel()
        await repository.complete()
        await refresh.value
        let completed = await repository.completed
        XCTAssertTrue(completed, "Refresh must finish fetching fresh data despite SwiftUI cancelling its caller")
        XCTAssertFalse(state.transactions.value.hasListError, "Cancelled refresh must not display Unable to load transactions")
        XCTAssertTrue(state.transactions.value.list.isLoaded)
    }

    func testExportSnapshotsAppliedQueryAndSuppressesCancelledCompletion() async throws {
        let state = FilterAppStateTestDouble()
        state.transactions.dispatch {
            $0.query = .init(search: "cocoa", action: .sell, filter: .init(group: .init(id: "cocoa", name: "Cocoa")))
        }
        let expectedQuery = state.transactions.value.query
        let started = expectation(description: "Download started")
        let documents = DeferredDocumentsService(started: started)
        let interactor = TransactionListInteractorImpl(appState: state, repository: EmptyTransactionListRepository())
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { interactor }.scope(.unique)
        AppContainer.shared.transactionDocumentsService.register { documents }.scope(.unique)
        AppContainer.shared.seasonCatalogueInteractor.register { EmptySeasonCatalogue() }.scope(.unique)
        AppContainer.shared.permissionsService.register { HomePermissionsServiceTestDouble() }.scope(.unique)
        AppContainer.shared.transactionsLocalRepository.register { HomeTransactionsLocalRepositoryTestDouble() }.scope(.unique)
        let viewModel = HomeModule.ViewModel()
        viewModel.startCSVExport()
        viewModel.startCSVExport()
        await fulfillment(of: [started], timeout: 2)
        let capturedQuery = await documents.query
        XCTAssertEqual(capturedQuery, expectedQuery)
        viewModel.cancelCSVExport()
        let unexpectedPresentation = expectation(description: "Cancelled export must stay hidden")
        unexpectedPresentation.isInverted = true
        let observation = viewModel.$showsCSVExporter.filter { $0 }.sink { _ in unexpectedPresentation.fulfill() }
        await documents.complete()
        await fulfillment(of: [unexpectedPresentation], timeout: 0.2)
        XCTAssertFalse(viewModel.isExportingCSV)
        XCTAssertNil(viewModel.csvDocument)
        observation.cancel()
    }

}

private struct EmptyTransactionListRepository: TransactionListRepository {
    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        .init(list: [], nextPage: nil, isCached: false)
    }
}

private struct EmptySeasonCatalogue: SeasonCatalogueInteractor {
    func groups() async throws -> CatalogueResult<CatalogueGroup> { .init(values: [], isCached: false) }
    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> { .init(values: [], isCached: false) }
}

private final class HomePermissionsServiceTestDouble: PermissionsServiceProtocol {
    let locationPermissionStatusValue: CLAuthorizationStatus = .denied
    let locationPermissionsStatus: AnyPublisher<CLAuthorizationStatus, Never> = Just(.denied).eraseToAnyPublisher()
    let notificationsPermissonsStatus: AnyPublisher<UNAuthorizationStatus, Never> = Just(.denied).eraseToAnyPublisher()

    func requestNotifications() async -> UNAuthorizationStatus {
        .denied
    }

    func requestLocations(upTo type: LocationAuthorization) async -> CLAuthorizationStatus? {
        .denied
    }

    func requestContacts() async -> CNAuthorizationStatus {
        .denied
    }
}

private final class HomeTransactionsLocalRepositoryTestDouble: TransactionsLocalRepository {
    func fetchTransactions(with pagination: TransactionsPagination) async throws -> TransactionsData {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func fetchTransaction(by id: String) async throws -> TransactionModel {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func fetchOnDiskTransactions() async throws -> IdentifiedArrayOf<TransactionModel> {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func confirmedUploadID(for queued: TransactionModel) throws -> String? {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func saveConfirmedUploadID(_ remoteID: String, for queued: TransactionModel) throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func replaceQueued(_ queued: TransactionModel, with transaction: TransactionModel) async throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func saveRefreshedDetails(_ model: TransactionModel, replacing previous: TransactionModel) async throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func saveStatusOutcome(_ models: [TransactionModel]) async throws { }

    func save(_ model: TransactionModel) async throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func saveProducerTransaction(
        commodityId: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        volume: String,
        inviteRecipient: RequestModels.CreateTransaction.Producer.TransactionData.Recipient?,
        isBuyingFromFarmer: Bool,
        season: HarvestSeason
    ) async throws -> TransactionModel {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func saveDownstreamTransaction(
        commodityId: String,
        volume: String,
        location: RequestModels.CreateTransaction.LocationType?,
        uploadFile: RequestModels.CreateTransaction.UploadFile?,
        farmCoordinates: CLLocationCoordinate2D?,
        transactionCoordinates: CLLocationCoordinate2D?,
        action: TransactionModel.Action,
        recipient: RequestModels.CreateTransaction.Downstream.TransactionData.Recipient,
        season: HarvestSeason?
    ) async throws -> TransactionModel {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func delete(_ transaction: TransactionModel) async throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }

    func deleteTxRecepient(_ user: UserModel?) async throws {
        throw HomeHarvestSeasonTestError.unexpectedCall
    }
}

private enum HomeHarvestSeasonTestError: Error {
    case unexpectedCall
}

private actor DeferredDocumentsService: TransactionDocumentsService {
    let started: XCTestExpectation
    private(set) var query: TransactionListQuery?
    private var continuation: CheckedContinuation<URLDocument, Never>?

    init(started: XCTestExpectation) { self.started = started }

    func downloadCSV(query: TransactionListQuery) async throws -> URLDocument {
        self.query = query
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            started.fulfill()
        }
    }

    func complete() {
        continuation?.resume(returning: .init("/tmp/fixture.csv"))
        continuation = nil
    }

    func downloadCSV(transactionId: String) async throws -> URLDocument { throw HomeHarvestSeasonTestError.unexpectedCall }
    func downloadDocumentsBundle(transactionId: String) async throws -> URLDocument { throw HomeHarvestSeasonTestError.unexpectedCall }
}

private actor HomeRefreshRepository: TransactionListRepository {
    let started: XCTestExpectation
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var completed = false

    init(started: XCTestExpectation) { self.started = started }

    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            started.fulfill()
        }
        try Task.checkCancellation()
        completed = true
        return .init(list: [], nextPage: nil, isCached: false)
    }

    func complete() {
        continuation?.resume()
        continuation = nil
    }
}
