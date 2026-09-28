//
//  SeasonalConversionTests.swift
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
import Utility
import Targets
import RestClient
import StorageKit
import Resources
@testable import CommonUI
@testable import Whimo

@MainActor
final class SeasonalConversionTests: XCTestCase {
    func testFinalConfirmationIdentifiesTestConversionAndCancelSendsNothing() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = ConversionFixture()
        let state = FilterAppStateTestDouble()
        let alerts = AlertManager()
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "conversion-confirmation-" + UUID().uuidString))
        defer { defaults.clear() }
        let modes = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        modes.select(.test)
        let transition = BusinessModeInteractorImpl(repository: modes, cleaner: PreloadUnusedCleaner(), appState: state)
        AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        AppContainer.shared.businessDataContext.register { [context = fixture.context] in context }.scope(.unique)
        AppContainer.shared.convertCommodityInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        let season = HarvestSeason(id: "stored-season", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .past)
        let model = ConvertCommodityDetailsModule.ViewModel(commodity: try XCTUnwrap(fixture.rule.inputs.first?.commodity),
                                                           convertionRule: fixture.rule, season: season)
        for _ in 0..<2 {
            model.didTapConvertCommodity()
            let shown = expectation(description: "Confirmation shown")
            DispatchQueue.main.async { shown.fulfill() }
            await fulfillment(of: [shown], timeout: 3)
            let alert = try XCTUnwrap(alerts.models.last)
            XCTAssertNotNil(alert.contentView, "Every final test Conversion needs the information block")
            XCTAssertEqual(alert.buttons.count, 2)
            alert.buttons.first?.action?()
            alerts.close()
            let closed = expectation(description: "Confirmation dismissed")
            DispatchQueue.main.async { closed.fulfill() }
            await fulfillment(of: [closed], timeout: 3)
            XCTAssertTrue(fixture.target.requests.isEmpty)
        }
    }

    func testConversionConfirmationSubmitsOnceAndInvalidatedFormCannotSubmit() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "conversion-actions-" + UUID().uuidString))
        defer { defaults.clear() }
        let modes = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        for testMode in [false, true] {
            modes.select(testMode ? .test : .ordinary)
            let context = BusinessDataContext()
            let fixture = ConversionFixture(context: context)
            let interactor = fixture.interactor
            let state = FilterAppStateTestDouble()
            let lists = ConversionLists()
            let alerts = AlertManager()
            let transition = BusinessModeInteractorImpl(repository: modes, cleaner: PreloadUnusedCleaner(), appState: state)
            AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
            AppContainer.shared.businessDataContext.register { context }.scope(.unique)
            AppContainer.shared.appState.register { state }.scope(.unique)
            AppContainer.shared.alertManager.register { alerts }.scope(.unique)
            AppContainer.shared.convertCommodityInteractor.register { interactor }.scope(.unique)
            AppContainer.shared.transactionListInteractor.register { TransactionListInteractorImpl(appState: state, repository: lists) }.scope(.unique)
            AppContainer.shared.balanceListInteractor.register { BalanceListInteractorImpl(appState: state, repository: lists) }.scope(.unique)
            let season = HarvestSeason(id: "stored-season", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .past)
            let commodity = try XCTUnwrap(fixture.rule.inputs.first?.commodity)
            let obsolete = ConvertCommodityDetailsModule.ViewModel(commodity: commodity, convertionRule: fixture.rule, season: season)
            for _ in 0..<2 {
                let model = ConvertCommodityDetailsModule.ViewModel(commodity: commodity, convertionRule: fixture.rule, season: season)
                model.didTapConvertCommodity()
                await confirmationUpdates()
                let alert = try XCTUnwrap(alerts.models.last)
                XCTAssertEqual(alert.contentView != nil, testMode)
                let ordinary = AlertManager.AlertModel.Features.ConfirmCommodityConversion.alert
                XCTAssertEqual(alert.title, ordinary.title)
                XCTAssertEqual(alert.buttons.map(\.title), ordinary.buttons.map(\.title))
                if !testMode { XCTAssertEqual(alert.subtitle, ordinary.subtitle) }
                let finished = expectation(description: "Conversion finished")
                let subscription = model.$hasConverted.filter { $0 }.prefix(1).sink { _ in finished.fulfill() }
                let convert = try XCTUnwrap(alert.buttons.last?.action)
                convert()
                convert()
                alerts.close()
                await fulfillment(of: [finished], timeout: 5)
                withExtendedLifetime(subscription) { }
                await model.submitConversion()
            }
            XCTAssertEqual(fixture.target.requests.count, 2)
            XCTAssertEqual(fixture.target.requests.first?.inputOverrides.count, 2)
            XCTAssertEqual(fixture.target.requests.first?.outputOverrides.count, 2)
            obsolete.didTapConvertCommodity()
            await confirmationUpdates()
            let oldAlert = try XCTUnwrap(alerts.models.last)
            try context.beginReset()
            context.finishReset()
            oldAlert.buttons.last?.action?()
            await confirmationUpdates()
            await obsolete.submitConversion()
            XCTAssertEqual(fixture.target.requests.count, 2, "Reset invalidates the whole Conversion draft")
            XCTAssertFalse(obsolete.hasConverted)
        }
    }

    private func confirmationUpdates() async {
        let delivered = expectation(description: "Confirmation state delivered")
        DispatchQueue.main.async { delivered.fulfill() }
        await fulfillment(of: [delivered], timeout: 3)
    }

    func testLocalizedFinalConversionConfirmationDesigns() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = ConversionFixture()
        let state = FilterAppStateTestDouble()
        let alerts = AlertManager()
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "conversion-designs-" + UUID().uuidString))
        defer { defaults.clear() }
        let modes = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        modes.select(.test)
        let transition = BusinessModeInteractorImpl(repository: modes, cleaner: PreloadUnusedCleaner(), appState: state)
        AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.alertManager.register { alerts }.scope(.unique)
        let model = ConvertCommodityDetailsModule.ViewModel(commodity: try XCTUnwrap(fixture.rule.inputs.first?.commodity),
                                                           convertionRule: fixture.rule)
        let previous = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previous, forKey: "currentLocalize") }
        for locale in [LocalizeKeys.english, .french, .spanish] {
            UserDefaults.standard.set(locale.rawValue, forKey: "currentLocalize")
            model.didTapConvertCommodity()
            await confirmationUpdates()
            let alert = try XCTUnwrap(alerts.models.last)
            XCTAssertEqual(alert.title, AppLocale.General.Alert.ConfirmCommodityConversion.title)
            try await attachConfirmation(alert, name: "conversion-\(locale.rawValue)")
            if locale == .spanish {
                try await attachConfirmation(alert, name: "conversion-es-accessibility", textSize: .accessibility5)
            }
            alerts.close()
            await confirmationUpdates()
        }
    }

    func testCanceledConversionReleasesItsLoaderWithoutSubmittingAgain() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = ConversionFixture()
        let state = FilterAppStateTestDouble()
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.businessDataContext.register { [context = fixture.context] in context }.scope(.unique)
        AppContainer.shared.convertCommodityInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        let season = HarvestSeason(id: "stored-season", name: "Cocoa", startDate: .distantPast, endDate: .distantFuture, status: .past)
        let model = ConvertCommodityDetailsModule.ViewModel(commodity: try XCTUnwrap(fixture.rule.inputs.first?.commodity),
                                                           convertionRule: fixture.rule, season: season)
        fixture.target.pause = true
        let task = Task { await model.submitConversion() }
        await fulfillment(of: [fixture.target.suspended], timeout: 5)
        task.cancel()
        fixture.target.resume()
        await task.value
        XCTAssertFalse(model.isSubmitting)
        XCTAssertFalse(model.hasConverted)
        XCTAssertFalse(state.system.value.isLoading)
        XCTAssertEqual(fixture.target.requests.count, 1)
    }

    func testEveryRecipeCommodityIsCoveredAndInheritedSeasonReachesRequest() async throws {
        let fixture = ConversionFixture()
        try await fixture.submit()
        XCTAssertEqual(fixture.target.coverageRequests.map(\.commodityIds), [["beans", "oil", "powder", "water"], ["beans", "oil", "powder", "water"]])
        XCTAssertEqual(fixture.target.requests.first?.harvestSeasonId, "stored-season")
        XCTAssertEqual(fixture.target.requests.first?.recipeId, "recipe")
        XCTAssertEqual(fixture.target.requests.first?.inputOverrides.map(\.quantity), [12, 3])
        XCTAssertEqual(fixture.target.requests.first?.outputOverrides.map(\.quantity), [7, 2])
    }
    func testActivePastAndArchivedCoverageKeepSameRequestIdentity() async throws {
        for status in [ResponseModels.HarvestSeason.Status.active, .past, .archived] {
            let fixture = ConversionFixture()
            fixture.target.status = status
            try await fixture.submit()
            XCTAssertEqual(fixture.target.requests.first?.harvestSeasonId, "stored-season")
        }
    }

    func testMissingCoverageAndUnavailableCatalogueNeverSubmit() async throws {
        let fixture = ConversionFixture()
        fixture.target.coverageAvailable = false
        do {
            try await fixture.submit()
            XCTFail("An incompatible recipe cannot execute")
        } catch ConversionError.coverage { }
        XCTAssertTrue(fixture.target.requests.isEmpty)
        fixture.target.coverageAvailable = true
        fixture.target.coverageError = RestClient.RestError.connectionLost
        do {
            try await fixture.submit()
            XCTFail("Conversion remains remote-only")
        } catch RestClient.RestError.connectionLost { }
        XCTAssertTrue(fixture.target.requests.isEmpty)
    }

    func testStaleCoverageAndSeasonalShortageAreSafeDomainErrors() async throws {
        let fixture = ConversionFixture()
        fixture.target.conversionError = RestClient.RestError.clientError(message: "private server detail", statusCode: .badRequest, serverErrorCode: nil)
        do {
            try await fixture.submit()
            XCTFail("Stale coverage must fail")
        } catch ConversionError.coverage { }
        fixture.target.conversionError = RestClient.RestError.clientError(message: "private seasonal balance", statusCode: .conflict, serverErrorCode: nil)
        do {
            try await fixture.submit()
            XCTFail("Insufficient balance must fail without adjustment")
        } catch ConversionError.insufficientBalance { }
        XCTAssertEqual(fixture.target.requests.map(\.harvestSeasonId), ["stored-season", "stored-season"])
    }

    func testFailureRetainsQuantitiesAndSeasonForSuccessfulRetry() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = ConversionFixture()
        let state = FilterAppStateTestDouble()
        let lists = ConversionLists()
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.businessDataContext.register { [context = fixture.context] in context }.scope(.unique)
        AppContainer.shared.convertCommodityInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { TransactionListInteractorImpl(appState: state, repository: lists) }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { BalanceListInteractorImpl(appState: state, repository: lists) }.scope(.unique)
        let season = HarvestSeason(id: "stored-season", name: "Archived", startDate: .distantPast, endDate: .distantFuture, status: .archive)
        let model = ConvertCommodityDetailsModule.ViewModel(commodity: try XCTUnwrap(fixture.rule.inputs.first?.commodity),
                                                           convertionRule: fixture.rule, season: season)
        model.inputCommodities[id: "beans"]?.quantity = "8.25"
        model.outputCommodities[id: "powder"]?.quantity = "6.5"
        fixture.target.conversionError = RestClient.RestError.clientError(message: "balance", statusCode: .conflict, serverErrorCode: nil)
        await model.submitConversion()
        XCTAssertFalse(model.hasConverted)
        XCTAssertFalse(model.isSubmitting)
        XCTAssertEqual(model.inputCommodities[id: "beans"]?.quantity, "8.25")
        XCTAssertEqual(model.outputCommodities[id: "powder"]?.quantity, "6.5")
        XCTAssertEqual(model.season, season)
        XCTAssertTrue(lists.balanceQueries.isEmpty)
        XCTAssertTrue(lists.transactionQueries.isEmpty)
        fixture.target.conversionError = nil
        lists.failRefresh = true
        await model.submitConversion()
        await model.submitConversion()
        XCTAssertTrue(model.hasConverted)
        XCTAssertTrue(state.balance.value.hasListError)
        XCTAssertTrue(state.transactions.value.hasListError)
        XCTAssertEqual(fixture.target.requests.count, 2)
        XCTAssertEqual(fixture.target.requests.last?.harvestSeasonId, "stored-season")
        XCTAssertEqual(fixture.target.requests.last?.outputOverrides.first?.quantity, 6.5)
    }

    func testConfirmationSuppressesDuplicateAndRefreshesBothAppliedQueries() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let fixture = ConversionFixture()
        let state = FilterAppStateTestDouble()
        let lists = ConversionLists()
        let transactions = TransactionListInteractorImpl(appState: state, repository: lists)
        let balances = BalanceListInteractorImpl(appState: state, repository: lists)
        let season = HarvestSeason(id: "stored-season", name: "Cocoa 2025/26", startDate: .distantPast, endDate: .distantFuture, status: .past)
        transactions.setQuery(.init(search: "sale", action: .sell, filter: .init(group: .init(id: "coffee", name: "Coffee"))))
        balances.setQuery(.init(search: "beans", filter: .init(group: .init(id: "cocoa", name: "Cocoa"), season: season)))
        let transactionQuery = transactions.query
        let balanceQuery = balances.query
        state.system[\.selectedTab] = .balance
        state.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.businessDataContext.register { [context = fixture.context] in context }.scope(.unique)
        AppContainer.shared.convertCommodityInteractor.register { [interactor = fixture.interactor] in interactor }.scope(.unique)
        AppContainer.shared.transactionListInteractor.register { transactions }.scope(.unique)
        AppContainer.shared.balanceListInteractor.register { balances }.scope(.unique)
        let commodity = try XCTUnwrap(fixture.rule.inputs.first?.commodity)
        let recipes = ConvertCommodityListModule.ViewModel(commodity: commodity, season: season)
        recipes.didTapOpenConverterDetails(model: fixture.rule)
        guard case .convertCommodityDetails(let captured, let recipe, let capturedSeason) = state.navigation.value.path.last?.screen else {
            return XCTFail("Recipe navigation must preserve the inherited row")
        }
        XCTAssertEqual(captured, commodity)
        XCTAssertEqual(capturedSeason, season)
        let model = ConvertCommodityDetailsModule.ViewModel(commodity: captured, convertionRule: recipe, season: capturedSeason)
        model.inputCommodities[id: "beans"]?.quantity = "11.5"
        fixture.target.pause = true
        let first = Task { await model.submitConversion() }
        await fulfillment(of: [fixture.target.suspended], timeout: 5)
        XCTAssertTrue(model.isSubmitting)
        await model.submitConversion()
        fixture.target.resume()
        await first.value
        await model.submitConversion()
        XCTAssertEqual(fixture.target.requests.count, 1)
        XCTAssertEqual(fixture.target.requests.first?.inputOverrides.first?.quantity, 11.5)
        XCTAssertEqual(fixture.target.requests.first?.harvestSeasonId, "stored-season")
        XCTAssertEqual(transactions.query, transactionQuery)
        XCTAssertEqual(balances.query, balanceQuery)
        XCTAssertEqual(lists.transactionQueries, [transactionQuery])
        XCTAssertEqual(lists.balanceQueries, [balanceQuery])
        XCTAssertEqual(state.system.value.selectedTab, .balance)
        XCTAssertEqual(state.navigation.value.path.count, 1)
        XCTAssertFalse(model.isSubmitting)
    }

}

@MainActor
private struct ConversionFixture {
    let target = ConversionTarget()
    let context: BusinessDataContext
    let interactor: ConvertCommodityInteractorImpl
    let rule: ConversionRuleModel

    init(context: BusinessDataContext = .init()) {
        self.context = context
        rule = .init(id: "recipe", name: "Press cocoa", inputs: [Self.item("beans", quantity: 12), Self.item("water", quantity: 3)],
                     outputs: [Self.item("powder", quantity: 7), Self.item("oil", quantity: 2)])
        let repository = CommodityConversionRemoteRepositoryImpl(commodityConversionTarget: target,
            commodityConversionMapper: CommodityConversionMapper(commoditiesGroupsMapper: CommoditiesGroupsMapper()), seasonsTarget: target)
        interactor = ConvertCommodityInteractorImpl(commodityConversionRemoteRepository: repository, businessDataContext: context)
    }

    func submit() async throws {
        try await interactor.makeConversion(rule: rule, seasonId: "stored-season",
            inputOverrides: .init(uniqueElements: rule.inputs), outputCommodities: .init(uniqueElements: rule.outputs))
    }

    static func item(_ id: String, quantity: Double) -> ConversionRuleModel.ConversionRuleItem {
        .init(id: id, commodity: .init(id: id, code: "1801", name: id, unit: "kg", balance: 100,
                                      hasRecipe: true, group: .init(id: "cocoa", name: "Cocoa")), quantity: quantity)
    }
}

@MainActor
private final class ConversionTarget: CommodityConversionTarget, HarvestSeasonsTarget {
    var requests: [RequestModels.MakeConversion] = []
    var status = ResponseModels.HarvestSeason.Status.archived
    var coverageAvailable = true
    var coverageError: Error?
    var conversionError: Error?
    var pause = false
    let suspended = XCTestExpectation(description: "Conversion request suspended")
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?
    func resume() {
        released = true
        continuation?.resume()
        continuation = nil
    }
    var coverageRequests: [RequestModels.HarvestSeasonsList] = []

    func seasons(_ request: RequestModels.HarvestSeasonsList) async throws -> ResponseModels.HarvestSeasonsInfo {
        coverageRequests.append(request)
        if let coverageError { throw coverageError }
        return .init(data: request.page == 1 || !coverageAvailable ? [] : [.init(id: "stored-season", name: "Backend name", startDate: "2025-01-01",
                                                        endDate: "2026-01-01", status: status)],
                     pagination: .init(pageSize: 100, nextPage: request.page == 1 ? 2 : nil, previousPage: nil, count: 1, totalPages: 2, page: request.page))
    }

    func getConversionRules(_ model: RequestModels.GetConversionRules) async throws -> ResponseModels.ConversionRules {
        .init(data: [], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 0, totalPages: 0, page: 1))
    }

    func makeConversion(_ model: RequestModels.MakeConversion) async throws {
        requests.append(model)
        if let conversionError { throw conversionError }
        if pause, !released {
            await withCheckedContinuation {
                continuation = $0
                suspended.fulfill()
            }
        }
    }
}

private final class ConversionLists: TransactionListRepository, SeasonalBalanceRepository {
    var failRefresh = false
    var transactionQueries: [TransactionListQuery] = []
    var balanceQueries: [BalanceListQuery] = []
    func page(query: TransactionListQuery, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        transactionQueries.append(query)
        if failRefresh { throw CocoaError(.fileReadUnknown) }
        return .init(list: [], nextPage: nil, isCached: false)
    }
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        balanceQueries.append(query)
        if failRefresh { throw CocoaError(.fileReadUnknown) }
        return .init(rows: [], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 0, totalPages: 0, page: 1),
                     message: nil, success: true)
    }
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance { throw SeasonalBalanceError.unavailableCache }
}
