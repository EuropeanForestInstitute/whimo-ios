//
//  TestTransactionConfirmationTests.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 15.09.2026.
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
import CoreLocation
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
    func testCreationFinalConfirmationIdentifiesTestDataOnEverySavePath() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let form = try await scenario.makeForm(type: .producer(seller: .farmer(isCurrentlyOnFarm: true)))
        let manager = AppContainer.shared.alertManager.resolve()
        for alternate in [false, true, false] {
            if alternate { form.saveTransactionWithNoLocation() } else { form.saveTransaction() }
            await confirmationUpdates()
            let alert = try XCTUnwrap(manager.models.last)
            XCTAssertNotNil(alert.contentView, "Every final test save needs the information block")
            XCTAssertEqual(alert.buttons.count, 2)
            manager.close()
            await confirmationUpdates()
            let sent = await scenario.target.producerRequests
            XCTAssertTrue(sent.isEmpty)
        }
    }

    @MainActor
    func testFinalCreationActionsPreserveModeValidationQueueAndDuplicateProtection() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let recipient = TransactionType.Recipient(recipientID: "other-participant", email: "", phone: "")
        let types: [TransactionType] = [.producer(seller: .farmer(isCurrentlyOnFarm: true)),
            .producer(seller: .cooperative()), .downstream(action: .buy, recipient: recipient),
            .downstream(action: .sell, recipient: recipient)]
        for testMode in [false, true] {
            let scenario = try ModeScenario(test: self, balances: ConfirmationBalance())
            defer { scenario.clearStorage() }
            if testMode {
                await scenario.settings.setTestModeEnabled(true)
                await scenario.settings.confirmTestModeEntry()
            }
            let manager = AppContainer.shared.alertManager.resolve()
            for type in types {
                let alternatePaths = type.isProducer ? [false, true] : [false]
                for alternate in alternatePaths {
                    let form = try await scenario.makeForm(type: type)
                    if alternate { scenario.state.createTransaction[\.farmLocation] = nil }
                    await confirmationUpdates()
                    if alternate { form.saveTransactionWithNoLocation() } else { form.saveTransaction() }
                    await confirmationUpdates()
                    let alert = try XCTUnwrap(manager.models.last)
                    XCTAssertEqual(alert.contentView != nil, testMode)
                    let ordinary = alternate ? AlertManager.AlertModel.Features.SaveTransactionWithNoLocation.alert
                        : AlertManager.AlertModel.Features.SaveTransaction.alert
                    XCTAssertEqual(alert.title, ordinary.title)
                    XCTAssertEqual(alert.buttons.map(\.title), ordinary.buttons.map(\.title))
                    if !testMode { XCTAssertEqual(alert.subtitle, ordinary.subtitle) }
                    let finished = expectation(description: "Final save finishes")
                    let subscription = scenario.state.system.state.map(\.isLoading).removeDuplicates()
                        .drop(while: { !$0 }).filter { !$0 }.prefix(1).sink { _ in finished.fulfill() }
                    let save = try XCTUnwrap(alert.buttons.first { $0.style == .prominent }?.action)
                    save()
                    save()
                    manager.close()
                    await fulfillment(of: [finished], timeout: 5)
                    withExtendedLifetime(subscription) { }
                    let producers = await scenario.target.producerRequests
                    let downstream = await scenario.target.requests
                    let queued = try await scenario.fixture.reopenedLocal().fetchOnDiskTransactions()
                    XCTAssertEqual(queued.count, producers.count + downstream.count)
                    XCTAssertEqual(queued.last?.volume, 10)
                    XCTAssertEqual(scenario.mode.mode, testMode ? .test : .ordinary)
                }
            }
            let producers = await scenario.target.producerRequests
            let downstream = await scenario.target.requests
            XCTAssertEqual(producers.count, 4, "Each confirmation sends once")
            XCTAssertEqual(producers.map { $0.transactionData.isBuyingFromFarmer }, [true, true, false, false])
            XCTAssertEqual(downstream.count, 2)
            XCTAssertEqual(downstream.map { $0.transactionData.action }, [.buy, .sell])
            let before = manager.models.count
            await scenario.target.goOnline()
            try await scenario.sync.syncTransactions()
            XCTAssertEqual(manager.models.count, before, "Queue upload has no manual reminder")
            let remaining = try await scenario.fixture.reopenedLocal().fetchOnDiskTransactions()
            XCTAssertTrue(remaining.isEmpty)
        }
    }

    @MainActor
    func testSettingsSwitchInvalidatesAnOpenCreationConfirmation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let form = try await scenario.makeForm(type: .producer(seller: .farmer(isCurrentlyOnFarm: true)))
        form.saveTransaction()
        await confirmationUpdates()
        let manager = AppContainer.shared.alertManager.resolve()
        let alert = try XCTUnwrap(manager.models.last)
        await scenario.settings.setTestModeEnabled(false)
        alert.buttons.last?.action?()
        await confirmationUpdates()
        XCTAssertFalse(scenario.state.system.value.isLoading)
        let sent = await scenario.target.producerRequests
        XCTAssertTrue(sent.isEmpty)
        XCTAssertEqual(scenario.state.system.value.selectedTab, .settings)
        let queued = try await scenario.fixture.reopenedLocal().fetchOnDiskTransactions()
        XCTAssertTrue(queued.isEmpty)
    }

    @MainActor
    func testLocalizedFinalCreationConfirmationDesigns() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let form = try await scenario.makeForm(type: .producer(seller: .cooperative()))
        let manager = AppContainer.shared.alertManager.resolve()
        let previous = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previous, forKey: "currentLocalize") }
        for locale in [LocalizeKeys.english, .french, .spanish] {
            UserDefaults.standard.set(locale.rawValue, forKey: "currentLocalize")
            for alternate in [false, true] {
                if alternate { form.saveTransactionWithNoLocation() } else { form.saveTransaction() }
                await confirmationUpdates()
                let alert = try XCTUnwrap(manager.models.last)
                XCTAssertEqual(alert.title, alternate ? AppLocale.General.Alert.SaveTransactionWithNoLocation.title
                    : AppLocale.General.Alert.SaveTransaction.title)
                try await attachConfirmation(alert, name: "creation-\(locale.rawValue)-\(alternate ? "no-location" : "save")")
                if locale == .french && alternate {
                    try await attachConfirmation(alert, name: "creation-fr-no-location-accessibility", textSize: .accessibility5)
                }
                manager.close()
                await confirmationUpdates()
            }
        }
    }

    @MainActor
    func testSettingsExitInvalidatesOpenAcceptanceConfirmation() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let scenario = try ModeScenario(test: self)
        defer { scenario.clearStorage() }
        await scenario.settings.setTestModeEnabled(true)
        await scenario.settings.confirmTestModeEntry()
        let fixture = try AcceptanceFixture(context: scenario.context)
        defer { fixture.storage.storage.clear(); fixture.defaults.clear() }
        fixture.mode.select(.test)
        let model = try await fixture.makeDetails(balances: AcceptanceBalanceRepository())
        await model.onAppear()
        let alerts = AppContainer.shared.alertManager()
        alerts.close()
        await confirmationUpdates()
        await model.didTapAcceptTransaction()
        await confirmationUpdates()
        let alert = try XCTUnwrap(alerts.models.last)
        XCTAssertTrue(fixture.target.requests.isEmpty)
        await scenario.settings.setTestModeEnabled(false)
        XCTAssertEqual(scenario.mode.mode, .ordinary)
        XCTAssertEqual(scenario.state.system.value.selectedTab, .settings)
        XCTAssertFalse(model.canAcceptTransaction)
        alert.buttons.last?.action?()
        alerts.close()
        await confirmationUpdates()
        XCTAssertTrue(fixture.target.requests.isEmpty)
        XCTAssertEqual(model.transaction.value?.status, .pending)
    }

    private func confirmationUpdates() async {
        let delivered = expectation(description: "Confirmation state delivered")
        DispatchQueue.main.async { delivered.fulfill() }
        await fulfillment(of: [delivered], timeout: 3)
    }

}

@MainActor
private extension ModeScenario {
    func makeForm(type: TransactionType) async throws -> CreateTransactionFormModule.ViewModel {
        await preload.prepareCatalogues()
        let seasons = try await creation.seasons(commodityId: "beans")
        let season = try XCTUnwrap(seasons.values.first { $0.status == .active })
        state.createTransaction.dispatch {
            $0.commodityType = BuyerVolumeTests.commodity
            $0.volumeAmount = "10"
            $0.seasonSelection = .init(commodityId: "beans", season: season)
            $0.farmLocation = .gps(coordinates: .init(latitude: 0, longitude: 0))
        }
        AppContainer.shared.transactionsInteractor.register { [transactions] in transactions }.scope(.unique)
        AppContainer.shared.locationService.register { ConfirmationLocation() }.scope(.unique)
        return .init(transactionType: type)
    }

}

private final class ConfirmationLocation: LocationServiceProtocol {
    let lastLocation = CLLocation(latitude: 0, longitude: 0)
    var lastLocationPublisher: AnyPublisher<CLLocation, Never> { Just(lastLocation).eraseToAnyPublisher() }
    let desiredAccuracy = kCLLocationAccuracyHundredMeters
    func startUpdatingLocation() { }
    func stopUpdatingLocation() { }
    func startUpdatingBGLocation() { }
    func stopUpdatingBGLocation() { }
    func getUserLocation() async -> CLLocation? { nil }
    func setLowAccuracy() { }
    func setBestAccuracy() { }
    func getPlace(for location: CLLocation) async throws -> CLPlacemark? { nil }
    func getCurrentPlace() async -> CLPlacemark? { nil }
}

private struct ConfirmationBalance: SeasonalBalanceRepository {
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        .init(volume: 100, traceability: nil, isCached: true)
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
}

@MainActor
extension XCTestCase {
    func attachConfirmation(_ alert: AlertManager.AlertModel, name: String, textSize: DynamicTypeSize = .large) async throws {
        let content = AlertView(alertModel: alert).frame(width: 328).environment(\.dynamicTypeSize, textSize)
        let image = try XCTUnwrap(ImageRenderer(content: content).uiImage)
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        defer { window.isHidden = true; previousWindow?.makeKey() }
        let appeared = expectation(description: "Final alert mounted")
        let host = UIHostingController(rootView: ZStack {
            Color.gray.opacity(0.3).ignoresSafeArea()
            content
        }.onAppear { appeared.fulfill() })
        window.rootViewController = host
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 3)
        host.view.layoutIfNeeded()
        if textSize.isAccessibilitySize {
            let scroll = try XCTUnwrap(confirmationScrollView(in: host.view))
            XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height,
                                 "Expanded information remains reachable through scrolling")
            XCTAssertGreaterThan(scroll.bounds.height, 0)
            scroll.setContentOffset(CGPoint(x: 0, y: max(0, scroll.contentSize.height - scroll.bounds.height)), animated: false)
            host.view.layoutIfNeeded()
        }
        let mounted = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let mountedAttachment = XCTAttachment(image: mounted)
        mountedAttachment.name = name + "-simulator"
        mountedAttachment.lifetime = .keepAlways
        add(mountedAttachment)
        if !textSize.isAccessibilitySize {
            XCTAssertLessThan(image.size.height, window.bounds.height, "Final actions fit the simulator viewport")
        }
    }
}

@MainActor
private func confirmationScrollView(in view: UIView) -> UIScrollView? {
    if let scroll = view as? UIScrollView { return scroll }
    return view.subviews.lazy.compactMap { confirmationScrollView(in: $0) }.first
}
