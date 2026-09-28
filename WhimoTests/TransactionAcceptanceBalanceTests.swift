//
//  TransactionAcceptanceBalanceTests.swift
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
import SwiftUI
import FactoryKit
import Combine
import Resources
@testable import CommonUI
@testable import Whimo

@MainActor
final class TransactionAcceptanceBalanceTests: XCTestCase {
    override func setUp() {
        super.setUp()

        AppContainer.shared.manager.push()
        let alerts = AlertManager()
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
    }
    override func tearDown() { AppContainer.shared.manager.pop(); super.tearDown() }

    func testTestAcceptanceWaitsForConfirmationAndDismissalPreservesPending() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        defer { fixture.defaults.clear() }
        fixture.mode.select(.test)
        let balances = AcceptanceBalanceRepository()
        balances.volume = 5
        let model = try await details(fixture, balances: balances)
        await settled(model)
        let alerts = AppContainer.shared.alertManager()
        for _ in 0..<2 {
            await model.didTapAcceptTransaction()
            await drainMainQueue()
            XCTAssertTrue(fixture.target.requests.isEmpty)
            XCTAssertEqual(model.transaction.value?.status, .pending)
            XCTAssertFalse(model.isSubmittingStatus)
            let alert = try XCTUnwrap(alerts.models.last)
            XCTAssertNotNil(alert.contentView)
            XCTAssertEqual(alert.buttons.count, 2)
            alerts.close()
            await drainMainQueue()
            XCTAssertTrue(alerts.models.isEmpty)
        }
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

    func testTestAcceptanceRejectsConfirmationAfterBusinessContextRoundTrip() async throws {
        let fixture = try AcceptanceFixture()
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let balances = AcceptanceBalanceRepository()
        balances.volume = 20
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.didTapAcceptTransaction()
        await drainMainQueue()
        let alerts = AppContainer.shared.alertManager()
        let alert = try XCTUnwrap(alerts.models.last)
        try fixture.context.beginReset()
        fixture.mode.select(.ordinary)
        fixture.context.finishReset()
        try fixture.context.beginReset()
        fixture.mode.select(.test)
        fixture.context.finishReset()
        alert.buttons.last?.action?()
        alerts.close()
        await drainMainQueue()
        await drainMainQueue()
        let finished = expectation(description: "Confirmation action finished")
        let observation = model.$isSubmittingStatus.filter { !$0 }.first().sink { _ in finished.fulfill() }
        await fulfillment(of: [finished], timeout: 5)
        observation.cancel()
        XCTAssertFalse(model.canAcceptTransaction, "Discarded Details cannot become eligible in a new dataset")
        XCTAssertTrue(fixture.target.requests.isEmpty)
        XCTAssertEqual(model.transaction.value?.status, .pending)
    }

    func testActiveShortageDisplaysMissingQuantityBeforeDirectAcceptance() async throws {
        let language = UserDefaults.standard.string(forKey: "currentLocalize")
        UserDefaults.standard.set("en", forKey: "currentLocalize")
        defer { UserDefaults.standard.set(language, forKey: "currentLocalize") }
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.volume = 5
        let model = try await details(fixture, balances: balances)
        await settled(model)
        let preview = try XCTUnwrap(model.acceptanceAutomaticPreview)
        XCTAssertEqual(preview.quantity, 7)
        XCTAssertEqual(String(preview.summary(locale: Locale(identifier: "en")).characters),
            "An automatic transaction will be created for the missing 7 kg. This amount will have incomplete traceability.")
        XCTAssertNil(model.acceptanceShortage)
        XCTAssertTrue(model.canAcceptTransaction)
        let reads = balances.exactQueries.count
        await model.didTapAcceptTransaction()
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertEqual(balances.exactQueries.count, reads)
        XCTAssertNil(model.acceptanceAutomaticPreview)
    }

    func testSeasonQuantityAndProvenanceMatrix() async throws {
        for status in ["past", "archived", "active"] {
            for volume in [0.0, 5, 12, 20] {
                for cached in [false, true] {
                    let fixture = try AcceptanceFixture(seasonStatus: status)
                    defer { fixture.storage.storage.clear() }
                    let balances = AcceptanceBalanceRepository()
                    balances.volume = volume
                    balances.isCached = cached
                    let model = try await details(fixture, balances: balances)
                    await settled(model)
                    let permitted = volume >= 12 || status == "active"
                    XCTAssertEqual(model.canAcceptTransaction, permitted, "\(status), \(volume), cached: \(cached)")
                    XCTAssertEqual(model.acceptanceShortage != nil, !permitted)
                    let expectedPreview: Double? = status == "active" ? [0.0: 12.0, 5: 7][volume] : nil
                    XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, expectedPreview)
                    XCTAssertEqual(balances.exactQueries.map { $0.0 }, ["beans"])
                    XCTAssertEqual(balances.exactQueries.map { $0.1 }, ["stored-season"])
                    let queryCount = balances.exactQueries.count
                    await model.didTapAcceptTransaction()
                    XCTAssertEqual(fixture.target.requests.count, permitted ? 1 : 0)
                    XCTAssertEqual(balances.exactQueries.count, queryCount, "Accept does not require another balance read")
                }
            }
        }
    }

    func testSavedAndRetainedBalanceRemainUsableDuringLoadAndFailure() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.savedVolume = 20
        balances.suspend = true
        balances.requested = expectation(description: "Fresh read suspended")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        XCTAssertTrue(model.isLoadingAcceptanceBalance)
        XCTAssertFalse(fixture.state.system.value.isLoading, "The global loader must not block saved balance actions")
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(model.acceptanceBalance?.isCached, true)
        balances.suspension?.resume(throwing: URLError(.badServerResponse))
        await settled(model)
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(model.acceptanceBalance?.volume, 20)
        balances.requested = expectation(description: "Retained read suspended")
        let refresh = Task { await model.refreshAcceptanceBalance() }
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        XCTAssertTrue(model.canAcceptTransaction)
        balances.suspension?.resume(returning: .init(volume: 5, traceability: nil, isCached: false))
        await refresh.value
        XCTAssertFalse(model.canAcceptTransaction)
        XCTAssertEqual(model.acceptanceShortage?.available, 5)
    }

    func testActivePreviewUsesSavedAndRetainedQuantityAfterFailedRefresh() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.savedVolume = 0
        balances.suspend = true
        balances.requested = expectation(description: "Saved zero while refreshing")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, 12)
        XCTAssertTrue(model.canAcceptTransaction)
        balances.suspension?.resume(throwing: URLError(.notConnectedToInternet))
        await settled(model)
        XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, 12)
        balances.suspend = false
        balances.requested = nil
        balances.volume = 5
        await model.refreshAcceptanceBalance()
        XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, 7)
        balances.error = URLError(.badServerResponse)
        await model.refreshAcceptanceBalance()
        XCTAssertEqual(model.acceptanceAutomaticPreview?.quantity, 7)
        XCTAssertTrue(model.canAcceptTransaction)
        balances.error = nil
        balances.volume = 12
        await model.refreshAcceptanceBalance()
        XCTAssertNil(model.acceptanceAutomaticPreview)
    }

    func testActivePreviewFormatsActualUnitAndLocalizedFractionalQuantity() async throws {
        let previousLanguage = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previousLanguage, forKey: "currentLocalize") }
        let fixture = try AcceptanceFixture(seasonStatus: "active")
        defer { fixture.storage.storage.clear() }
        fixture.target.requestedVolume = 2000
        fixture.target.unit = "L"
        let balances = AcceptanceBalanceRepository()
        balances.volume = 765.75
        let model = try await details(fixture, balances: balances)
        await settled(model)
        let preview = try XCTUnwrap(model.acceptanceAutomaticPreview)
        XCTAssertEqual(preview.quantity, 1234.25)
        for (language, amount, automatic, traceability) in [
            (LocalizeKeys.english, "1,234.25 L", "automatic transaction", "incomplete traceability"),
            (.french, "1\u{202f}234,25 L", "transaction automatique", "traçabilité incomplète"),
            (.spanish, "1234,25 L", "transacción automática", "trazabilidad incompleta")
        ] {
            UserDefaults.standard.set(language.rawValue, forKey: "currentLocalize")
            let summary = preview.summary(locale: language.locale)
            XCTAssertTrue(String(summary.characters).contains(amount), String(summary.characters))
            for phrase in [automatic, traceability] {
                let range = try XCTUnwrap(summary.range(of: phrase))
                XCTAssertNotNil(summary[range].font)
            }
        }
    }

    func testBalanceCompletionCannotClearAnOverlappingSubmissionLoader() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.savedVolume = 20
        balances.suspend = true
        balances.requested = expectation(description: "Balance pending")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        fixture.target.statusRequested = expectation(description: "Submission pending")
        let submit = Task { await model.didTapAcceptTransaction() }
        await fulfillment(of: [try XCTUnwrap(fixture.target.statusRequested)], timeout: 5)
        XCTAssertTrue(fixture.state.system.value.isLoading)
        balances.suspension?.resume(returning: .init(volume: 20, traceability: nil, isCached: false))
        await settled(model)
        await drainMainQueue()
        XCTAssertTrue(fixture.state.system.value.isLoading)
        XCTAssertTrue(model.isSubmittingStatus)
        fixture.target.statusSuspension?.resume()
        await submit.value
        XCTAssertFalse(fixture.state.system.value.isLoading)
    }

    func testUnknownFailureAndRetryDoNotInventZero() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "archived")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.suspend = true
        balances.requested = expectation(description: "Unknown loading")
        let model = try await details(fixture, balances: balances)
        await fulfillment(of: [try XCTUnwrap(balances.requested)], timeout: 5)
        XCTAssertTrue(model.isAcceptanceBalanceUnavailable)
        XCTAssertFalse(model.canAcceptTransaction)
        XCTAssertNil(model.acceptanceShortage)
        XCTAssertNil(model.acceptanceAutomaticPreview)
        await model.didTapAcceptTransaction()
        XCTAssertTrue(fixture.target.requests.isEmpty)
        balances.suspension?.resume(throwing: URLError(.notConnectedToInternet))
        await settled(model)
        XCTAssertTrue(model.hasAcceptanceBalanceError)
        XCTAssertNil(model.acceptanceBalance)
        balances.suspend = false
        balances.requested = nil
        balances.volume = 12
        await model.refreshAcceptanceBalance()
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertFalse(model.hasAcceptanceBalanceError)
        XCTAssertFalse(model.isAcceptanceBalanceUnavailable)
    }

    func testMissingMetadataRetriesAndRetainsKnownSeasonOnRefreshError() async throws {
        var fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        fixture.pending.harvestSeason = nil
        fixture.target.missingSeason = true
        let balances = AcceptanceBalanceRepository()
        balances.volume = 20
        let model = try await details(fixture, balances: balances)
        await settled(model)
        XCTAssertFalse(model.canAcceptTransaction)
        XCTAssertTrue(model.isAcceptanceBalanceUnavailable)
        fixture.target.missingSeason = false
        await model.refreshAcceptanceBalance()
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertEqual(model.transaction.value?.harvestSeason?.status, .past)

        fixture.target.fetchError = URLError(.badServerResponse)
        let reopened = try await details(fixture, balances: balances)
        await settled(reopened)
        // The fixture's stored snapshot is deliberately still missing metadata.
        XCTAssertFalse(reopened.canAcceptTransaction)
        fixture.pending.harvestSeason = model.transaction.value?.harvestSeason
        let retained = try await details(fixture, balances: balances)
        await settled(retained)
        XCTAssertTrue(retained.canAcceptTransaction)
        XCTAssertEqual(retained.transaction.value?.harvestSeason?.status, .past)
    }

    func testParticipantGuardAndForeignSeasonListPreserveExactScope() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.volume = 20
        let profile = AcceptanceProfile()
        let model = try await details(fixture, balances: balances, profile: profile)
        await settled(model)
        profile.participantId = "other"
        XCTAssertFalse(model.canAcceptTransaction)
        XCTAssertNil(model.acceptanceShortage)
        XCTAssertNil(model.acceptanceAutomaticPreview)
        await model.didTapAcceptTransaction()
        XCTAssertTrue(fixture.target.requests.isEmpty)
        profile.participantId = "seller"
        var other = fixture.pending
        other.harvestSeasonId = "other-season"
        other.harvestSeason = .init(id: "other-season", name: "Other", startDate: .distantPast, endDate: .distantFuture, status: .past)
        fixture.state.transactions.dispatch { $0.list = .loaded(value: [other]) }
        await drainMainQueue()
        XCTAssertTrue(model.canAcceptTransaction)
        XCTAssertFalse(model.isAcceptanceBalanceUnavailable)
        XCTAssertEqual(model.transaction.value?.harvestSeasonId, "stored-season")
        XCTAssertNil(model.acceptanceShortage)
    }

    func testPopupExplainsZeroAndDismissalHasNoTransactionOrNavigationAction() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "archived")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.volume = 0
        let alerts = AlertManager()
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        let model = try await details(fixture, balances: balances)
        await settled(model)
        let shortage = try XCTUnwrap(model.acceptanceShortage)
        XCTAssertEqual(shortage.available, 0)
        XCTAssertEqual(shortage.requested, 12)
        XCTAssertEqual(shortage.unit, "kg")
        XCTAssertEqual(shortage.season.name, "Cocoa 2025/26")
        XCTAssertTrue(String(shortage.summary(locale: Locale(identifier: "en")).characters).contains("0 kg"))
        let path = fixture.state.navigation.value.path
        for _ in 0..<2 {
            model.showAcceptanceShortage()
            await drainMainQueue()
            let alert = try XCTUnwrap(alerts.models.last)
            XCTAssertEqual(alert.title, AppLocale.TransactionAcceptance.Balance.title)
            XCTAssertEqual(alert.buttons.count, 1)
            XCTAssertNil(alert.buttons.first?.action, "Got It has no mutation action")
            alerts.close()
            await drainMainQueue()
            XCTAssertTrue(alerts.models.isEmpty)
        }
        XCTAssertTrue(fixture.target.requests.isEmpty)
        XCTAssertEqual(model.transaction.value?.status, .pending)
        XCTAssertEqual(fixture.state.navigation.value.path, path)
    }

    func testRejectBuyerAndOfflineSubmissionKeepExistingBehavior() async throws {
        let fixture = try AcceptanceFixture(seasonStatus: "past")
        defer { fixture.storage.storage.clear() }
        let balances = AcceptanceBalanceRepository()
        balances.error = URLError(.notConnectedToInternet)
        let model = try await details(fixture, balances: balances)
        await settled(model)
        await model.didTapRejectTransaction()
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertEqual(model.transaction.value?.status, .rejected)

        var buyer = try AcceptanceFixture(seasonStatus: "archived")
        defer { buyer.storage.storage.clear() }
        buyer.target.buyerRecipient = true
        buyer.pending = buyer.storage.mapper.toDomain(from: try buyer.target.decodeTransaction(status: "pending"))
        let profile = AcceptanceProfile()
        profile.participantId = "buyer"
        let buyerModel = try await details(buyer, balances: balances, profile: profile)
        XCTAssertFalse(buyerModel.requiresAcceptanceBalance)
        XCTAssertTrue(buyerModel.canAcceptTransaction)
        await buyerModel.didTapAcceptTransaction()
        XCTAssertEqual(buyer.target.requests.count, 1)

        let offline = try AcceptanceFixture(seasonStatus: "past")
        defer { offline.storage.storage.clear() }
        balances.error = nil
        balances.volume = 20
        balances.isCached = true
        offline.target.statusError = URLError(.notConnectedToInternet)
        let offlineModel = try await details(offline, balances: balances)
        await settled(offlineModel)
        await offlineModel.didTapAcceptTransaction()
        XCTAssertEqual(offline.target.requests.count, 1)
        XCTAssertEqual(offlineModel.transaction.value?.status, .pending)
        XCTAssertNil(offlineModel.statusOutcome)
        offline.target.statusError = nil
        await offlineModel.onAppear()
        await offlineModel.onForeground()
        XCTAssertEqual(offline.target.requests.count, 1, "Reconnection refresh cannot submit acceptance")
        let stored = try await offline.local.fetchTransaction(by: "ordinary")
        XCTAssertEqual(stored.status, .pending)
        XCTAssertEqual(stored.persistingData.state, .sync)
    }

    func details(_ fixture: AcceptanceFixture, balances: AcceptanceBalanceRepository,
                 profile: AcceptanceProfile = AcceptanceProfile(), savePending: Bool = true) async throws -> TransactionDetailsModule.ViewModel {
        let model = try await fixture.makeDetails(balances: balances, profile: profile, savePending: savePending)
        let loaded = expectation(description: "Details loaded")
        let observation = model.$transaction.filter(\.isLoaded).first().sink { _ in loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 5)
        observation.cancel()
        return model
    }

    func settled(_ model: TransactionDetailsModule.ViewModel) async {
        let complete = expectation(description: "Balance lookup finished")
        let observation = model.$isRefreshing.filter { !$0 }.first().sink { _ in complete.fulfill() }
        await fulfillment(of: [complete], timeout: 5)
        observation.cancel()
    }

    func drainMainQueue() async {
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
    }
}
