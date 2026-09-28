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
import Combine
import FactoryKit
import Resources
@testable import CommonUI
@testable import Whimo

extension TransactionAcceptanceBalanceTests {
    func testConfirmedTestAcceptanceSubmitsOnceAndKeepsBackendOutcomeSeparate() async throws {
        let fixture = try AcceptanceFixture(automatic: true)
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let balances = AcceptanceBalanceRepository()
        balances.volume = 2
        let model = try await details(fixture, balances: balances)
        await settled(model)
        let alerts = AppContainer.shared.alertManager()
        await model.didTapAcceptTransaction()
        await model.didTapAcceptTransaction()
        await drainMainQueue()
        XCTAssertEqual(alerts.models.count, 1)
        XCTAssertTrue(fixture.target.requests.isEmpty)
        let alert = try XCTUnwrap(alerts.models.last)
        let confirm = try XCTUnwrap(alert.buttons.last?.action)
        fixture.target.statusRequested = expectation(description: "Confirmed acceptance suspended")
        confirm()
        confirm()
        alerts.close()
        await fulfillment(of: [try XCTUnwrap(fixture.target.statusRequested)], timeout: 5)
        await model.didTapAcceptTransaction()
        await model.didTapRejectTransaction()
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertTrue(model.isSubmittingStatus)
        fixture.target.statusSuspension?.resume()
        await statusSettled(model)
        XCTAssertEqual(model.transaction.value?.status, .accepted)
        XCTAssertEqual(model.statusOutcome?.automaticTransaction?.volume, 7, "Backend result overrides the ten-unit preview")
        XCTAssertEqual(alerts.models.last?.subtitle, AppLocale.TransactionAcceptance.automatic("7", "kg"))
        XCTAssertNil(alerts.models.last?.contentView, "The result is separate from the pre-submission warning")
        confirm()
        await model.didTapAcceptTransaction()
        XCTAssertEqual(fixture.target.requests.count, 1)
    }

    func testDismissedAndReplacedConfirmationCallbacksCannotAccept() async throws {
        let fixture = try AcceptanceFixture()
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let model = try await details(fixture, balances: AcceptanceBalanceRepository())
        await settled(model)
        let alerts = AppContainer.shared.alertManager()
        await model.didTapAcceptTransaction()
        await drainMainQueue()
        let dismissed = try XCTUnwrap(alerts.models.last)
        alerts.close()
        await drainMainQueue()
        await model.didTapAcceptTransaction()
        await drainMainQueue()
        dismissed.buttons.last?.action?()
        await drainMainQueue()
        XCTAssertTrue(fixture.target.requests.isEmpty)
        XCTAssertEqual(alerts.models.count, 1)
        let current = try XCTUnwrap(alerts.models.last)
        model.onDisappear()
        current.buttons.last?.action?()
        await drainMainQueue()
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

    func testTestConfirmationRevalidatesChangedEligibilityAndTransaction() async throws {
        for change in ["shortage", "season", "participant", "status", "quantity"] {
            let fixture = try AcceptanceFixture(seasonStatus: change == "season" ? "active" : "past")
            defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
            fixture.mode.select(.test)
            let balances = AcceptanceBalanceRepository()
            balances.volume = change == "season" ? 5 : 20
            let profile = AcceptanceProfile()
            let model = try await details(fixture, balances: balances, profile: profile)
            await settled(model)
            let alerts = AppContainer.shared.alertManager()
            await model.didTapAcceptTransaction()
            await drainMainQueue()
            let alert = try XCTUnwrap(alerts.models.last)
            switch change {
                case "shortage": balances.volume = 0
                case "season": fixture.target.seasonStatus = "past"
                case "participant": profile.participantId = "unrelated"
                case "status": fixture.target.fetchStatus = "rejected"
                default: fixture.target.requestedVolume = 13
            }
            // A new Details response/quantity or participant invalidates the reviewed action.
            if change != "participant" { await model.refresh() }
            alert.buttons.last?.action?()
            alerts.close()
            await drainMainQueue()
            await statusSettled(model)
            XCTAssertTrue(fixture.target.requests.isEmpty, change)
        }
    }

    func testTestModeBlockedAcceptanceNeverShowsConfirmation() async throws {
        for reason in ["shortage", "unavailable", "metadata", "creator", "outsider"] {
            let fixture = try AcceptanceFixture(seasonStatus: "archived")
            defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
            fixture.mode.select(.test)
            let balances = AcceptanceBalanceRepository()
            balances.volume = reason == "shortage" ? 0 : 20
            if reason == "unavailable" { balances.error = URLError(.notConnectedToInternet) }
            let profile = AcceptanceProfile()
            if reason == "creator" { profile.participantId = "buyer" }
            if reason == "outsider" { profile.participantId = "unrelated" }
            if reason == "metadata" { fixture.target.missingSeason = true }
            var snapshot = fixture
            if reason == "metadata" { snapshot.pending.harvestSeason = nil }
            let model = try await details(snapshot, balances: balances, profile: profile)
            await settled(model)
            await model.didTapAcceptTransaction()
            await drainMainQueue()
            XCTAssertFalse(model.canAcceptTransaction, reason)
            XCTAssertTrue(fixture.target.requests.isEmpty, reason)
            XCTAssertTrue(AppContainer.shared.alertManager().models.isEmpty, reason)
        }
    }

    func testTestModeBuyerAcceptanceAndRejectKeepExistingRules() async throws {
        for participant in ["buyer", "seller"] {
            var fixture = try AcceptanceFixture(seasonStatus: "archived")
            defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
            fixture.mode.select(.test)
            fixture.target.buyerRecipient = true
            fixture.pending = fixture.storage.mapper.toDomain(from: try fixture.target.decodeTransaction(status: "pending"))
            let profile = AcceptanceProfile()
            profile.participantId = participant
            let balances = AcceptanceBalanceRepository()
            balances.error = URLError(.notConnectedToInternet)
            let model = try await details(fixture, balances: balances, profile: profile)
            await settled(model)
            if participant == "buyer" {
                XCTAssertTrue(model.canAcceptTransaction)
                await model.didTapAcceptTransaction()
                await drainMainQueue()
                let alerts = AppContainer.shared.alertManager()
                XCTAssertTrue(fixture.target.requests.isEmpty)
                alerts.models.last?.buttons.last?.action?()
                alerts.close()
                await drainMainQueue()
                await statusSettled(model)
                XCTAssertEqual(model.transaction.value?.status, .accepted)
            } else {
                XCTAssertTrue(model.waitingCreatorResponse)
                await model.didTapRejectTransaction()
                XCTAssertEqual(model.transaction.value?.status, .rejected)
            }
            XCTAssertEqual(fixture.target.requests.count, 1)
        }
    }

    func testTestAcceptanceFailureAndConflictRequireFreshConfirmation() async throws {
        for conflict in [false, true] {
            let fixture = try AcceptanceFixture(seasonStatus: "past")
            defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
            fixture.mode.select(.test)
            fixture.target.conflict = conflict
            if !conflict { fixture.target.statusError = URLError(.notConnectedToInternet) }
            let balances = AcceptanceBalanceRepository()
            balances.volume = 20
            let model = try await details(fixture, balances: balances)
            await settled(model)
            let alerts = AppContainer.shared.alertManager()
            for count in 1...2 {
                await model.didTapAcceptTransaction()
                await drainMainQueue()
                let alert = try XCTUnwrap(alerts.models.last)
                XCTAssertNotNil(alert.contentView)
                XCTAssertEqual(fixture.target.requests.count, count - 1)
                alert.buttons.last?.action?()
                alerts.close()
                await drainMainQueue()
                await statusSettled(model)
                XCTAssertEqual(fixture.target.requests.count, count)
                XCTAssertEqual(model.transaction.value?.status, .pending)
                XCTAssertNil(model.statusOutcome)
                alert.buttons.last?.action?()
                await drainMainQueue()
                XCTAssertEqual(fixture.target.requests.count, count, "The consumed action cannot be replayed after failure")
            }
        }
    }

    func testLocalizedTestAcceptanceConfirmationFitsSimulator() async throws {
        let original = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(original, forKey: "currentLocalize") }
        let fixture = try AcceptanceFixture()
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let model = try await details(fixture, balances: AcceptanceBalanceRepository())
        await settled(model)
        let alerts = AppContainer.shared.alertManager()
        for (language, title) in [("en", "Accept test transaction?"),
                                  ("fr", "Accepter la transaction de test ?"),
                                  ("es", "¿Aceptar la transacción de prueba?")] {
            UserDefaults.standard.set(language, forKey: "currentLocalize")
            await model.didTapAcceptTransaction()
            await drainMainQueue()
            let alert = try XCTUnwrap(alerts.models.last)
            XCTAssertEqual(alert.title, title)
            XCTAssertEqual(alert.buttons.last?.title, AppLocale.TransactionDetails.ForMe.Buttons.accept)
            try await attachConfirmation(alert, name: "acceptance-" + language)
            if language == "fr" {
                try await attachConfirmation(alert, name: "acceptance-fr-accessibility", textSize: .accessibility5)
            }
            alerts.close()
            await drainMainQueue()
        }
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

    func testModeExitDuringAcceptanceCannotPublishIntoNewContext() async throws {
        let fixture = try AcceptanceFixture()
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let model = try await details(fixture, balances: AcceptanceBalanceRepository())
        await settled(model)
        let alerts = AppContainer.shared.alertManager()
        await model.didTapAcceptTransaction()
        await drainMainQueue()
        fixture.target.statusRequested = expectation(description: "Acceptance pending at mode exit")
        alerts.models.last?.buttons.last?.action?()
        alerts.close()
        await fulfillment(of: [try XCTUnwrap(fixture.target.statusRequested)], timeout: 5)
        try fixture.context.beginReset()
        fixture.mode.select(.ordinary)
        fixture.context.finishReset()
        fixture.state.system[\.isLoading] = true
        fixture.target.statusSuspension?.resume()
        await statusSettled(model)
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertNil(model.statusOutcome)
        XCTAssertEqual(model.transaction.value?.status, .pending)
        XCTAssertTrue(alerts.models.isEmpty)
        XCTAssertTrue(fixture.state.system.value.isLoading, "Old completion cannot clear a new context's loader")
    }

    func statusSettled(_ model: TransactionDetailsModule.ViewModel) async {
        let finished = expectation(description: "Status operation finished")
        let observation = model.$isSubmittingStatus.filter { !$0 }.first().sink { _ in finished.fulfill() }
        await fulfillment(of: [finished], timeout: 5)
        observation.cancel()
    }
}
