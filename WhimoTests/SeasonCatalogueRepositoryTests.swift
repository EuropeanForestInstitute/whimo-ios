//
//  SeasonCatalogueRepositoryTests.swift
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
import FactoryKit
import Networking
import StorageKit
import DatabaseKit
import GRDB
import RestClient
import Targets
@testable import Whimo

final class SeasonCatalogueRepositoryTests: XCTestCase {
    func testCommoditySelectionLoadsEveryPage() async throws {
        let repository = CommodityRemoteRepositoryImpl(commoditiesTarget: CatalogueTargetDouble(),
            commoditiesGroupsMapper: CommoditiesGroupsMapper())
        let groups = try await repository.fetchCommodityGroups()
        XCTAssertEqual(groups.map(\.id), ["no-balance", "cocoa"])
    }

    func testFullCataloguePagingAndCoverageCacheSurviveRepositoryRecreation() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = CatalogueTargetDouble()
        let repository = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target,
                                                       database: database, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        let groups = try await repository.groups()
        XCTAssertEqual(groups.values.map(\.id), ["no-balance", "cocoa"])
        XCTAssertFalse(groups.isCached)
        let seasons = try await repository.seasons(groupId: "cocoa")
        XCTAssertEqual(seasons.values.map(\.id), ["active-a", "active-b", "old"])
        XCTAssertEqual(seasons.values.map(\.status), [.active, .active, .archive])
        XCTAssertEqual(seasons.values.first?.name, "Backend label")
        let empty = try await repository.seasons(groupId: "no-balance")
        XCTAssertTrue(empty.values.isEmpty)
        await target.goOffline()
        let restored = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target,
                                                    database: database, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        let cached = try await restored.seasons(groupId: "cocoa")
        XCTAssertTrue(cached.isCached)
        XCTAssertEqual(cached.values, seasons.values)
        let cachedEmpty = try await restored.seasons(groupId: "no-balance")
        XCTAssertTrue(cachedEmpty.isCached)
        XCTAssertTrue(cachedEmpty.values.isEmpty)
        let cachedGroups = try await restored.groups()
        XCTAssertEqual(cachedGroups.values, groups.values)
        do {
            _ = try await restored.seasons(groupId: "uncached")
            XCTFail("A missing query cache must not be presented as an empty catalogue")
        } catch RestClient.RestError.connectionLost { }
    }

    func testCommodityCoverageHasItsOwnDurableCache() async throws {
        let database = try DatabaseImpl(writer: DatabaseQueue())
        let target = CatalogueTargetDouble()
        let repository = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target,
                                                       database: database, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        _ = try await repository.seasons(groupId: "cocoa")
        let seasons = try await repository.seasons(commodityId: "beans")
        XCTAssertEqual(seasons.values.map(\.id), ["active-a", "old"])
        await target.goOffline()
        let restored = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target,
                                                    database: database, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        let cached = try await restored.seasons(commodityId: "beans")
        XCTAssertTrue(cached.isCached)
        XCTAssertEqual(cached.values, seasons.values)
        do {
            _ = try await restored.seasons(commodityId: "cocoa")
            XCTFail("Group coverage must never stand in for commodity coverage")
        } catch RestClient.RestError.connectionLost { }
    }

    @MainActor
    func testCommodityCacheSurvivesRealOfflineTransportAndDatabaseReopening() async throws {
        try await exerciseOfflineVolume(action: .buy)
    }

    @MainActor
    func testSellerUsesReopenedCatalogueAndExactBalanceCacheUnderTheSameGuard() async throws {
        try await exerciseOfflineVolume(action: .sell)
    }

    @MainActor
    private func exerciseOfflineVolume(action: TransactionModel.Action) async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let commodity = BuyerVolumeTests.commodity
        state.createTransaction[\.commodityType] = commodity
        AppContainer.shared.appState.register { state }.scope(.unique)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("catalogue.sqlite").path
        let target = CatalogueTargetDouble()
        let database = try DatabaseImpl(writer: DatabaseQueue(path: path))
        let online = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: target,
                                                   database: database, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        AppContainer.shared.creationSeasonInteractor.register {
            CreationSeasonInteractorImpl(catalogue: online, balances: SeasonalBalanceRepositoryImpl(
                target: target, database: database, mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()),
                accountId: { "fixture" }))
        }.scope(.unique)
        let first = CommodityVolumeModule.ViewModel(volumeAmount: "60", commodityType: commodity,
            transactionType: .downstream(action: action, recipient: .empty))
        await first.loadSeasons()
        XCTAssertFalse(first.seasons.isEmpty)
        let selected = try XCTUnwrap(first.seasons.first(where: { $0.status == .past }))
        first.selectSeason(selected)
        await first.loadBalance()
        XCTAssertTrue(first.canConfirm)
        first.didTapConfirm()
        let storage = AnyStorage(state: UserDefaultsStore(suiteName: "catalogue-test-" + UUID().uuidString))
        defer { storage.clear() }
        let client = RestClient(baseURL: try XCTUnwrap(URL(string: "https://catalogue.invalid")),
                                connectivity: CatalogueOfflineConnectivity(), userDefaults: storage)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: path))
        let offline = SeasonCatalogueRepositoryImpl(groupsTarget: target, seasonsTarget: RestHarvestSeasonsTarget(restClient: client),
                                                    database: reopened, mapper: SeasonCatalogueMapper(),
                                                       accountId: { "fixture" })
        AppContainer.shared.creationSeasonInteractor.register {
            CreationSeasonInteractorImpl(catalogue: offline, balances: SeasonalBalanceRepositoryImpl(
                target: RestBalancesTarget(restClient: client), database: reopened, mapper: SeasonalBalanceMapper(seasonMapper: SeasonCatalogueMapper()),
                accountId: { "fixture" }))
        }.scope(.unique)
        let restored = CommodityVolumeModule.ViewModel(volumeAmount: state.createTransaction.value.volumeAmount, commodityType: commodity,
            transactionType: .downstream(action: action, recipient: .empty))
        await restored.loadSeasons()
        await restored.loadBalance()
        XCTAssertFalse(restored.seasons.isEmpty, "Previously loaded commodity seasons must remain visible offline")
        XCTAssertEqual(restored.seasons, first.seasons)
        XCTAssertEqual(restored.selectedSeason?.id, selected.id)
        XCTAssertFalse(restored.catalogueUnavailable)
        XCTAssertTrue(restored.canConfirm)
        XCTAssertEqual(restored.seasonalBalance?.volume, 60)
        XCTAssertEqual(restored.seasonalBalance?.isCached, true)
        restored.volumeText = "61"
        XCTAssertEqual(restored.canConfirm, action == .buy)
        XCTAssertEqual(restored.hasSeasonalShortage, action == .sell)
        restored.volumeText = "60"
        restored.didTapConfirm()
        XCTAssertEqual(state.createTransaction.value.seasonSelection?.season.id, "old")
        XCTAssertEqual(state.createTransaction.value.volumeAmount, "60")
    }

    func testSeasonDatesUseGregorianUTCAndInvalidDatesFail() throws {
        let mapper = SeasonCatalogueMapper()
        let season = try mapper.toDomain(from: .init(
            id: "opaque", name: "Admin label", startDate: "2025-09-01", endDate: "2026-09-01", status: .past
        ))
        XCTAssertEqual(season.startDate.timeIntervalSince1970, 1_756_684_800)
        XCTAssertEqual(season.name, "Admin label")
        XCTAssertThrowsError(try mapper.toDomain(from: .init(
            id: "invalid", name: "Invalid", startDate: "bad", endDate: "2026-09-01", status: .active
        )))
    }
}

actor CatalogueTargetDouble: CommoditiesTarget, HarvestSeasonsTarget, BalancesTarget {
    private var offline = false
    func goOffline() { offline = true }

    func commodityGroupsList(_ model: RequestModels.CommodityGroupsList) async throws -> ResponseModels.CommodityGroupInfo {
        if offline { throw RestClient.RestError.connectionLost }
        let first = model.pageData.page == 1
        return .init(data: [.init(id: first ? "no-balance" : "cocoa", name: first ? "Coffee" : "Cocoa", commodities: [])],
                     pagination: .init(pageSize: 1, nextPage: first ? 2 : nil, previousPage: first ? nil : 1,
                                       count: 2, totalPages: 2, page: model.pageData.page))
    }

    func seasons(_ request: RequestModels.HarvestSeasonsList) async throws -> ResponseModels.HarvestSeasonsInfo {
        if offline { throw RestClient.RestError.connectionLost }
        let data: [ResponseModels.HarvestSeason]
        if request.commodityId == "beans" {
            data = [season("active-a", .active), season("old", .past)]
        } else if request.commodityGroupId == "no-balance" {
            data = []
        } else if request.page == 1 {
            data = [season("active-a", .active), season("active-b", .active)]
        } else {
            data = [season("old", .archived)]
        }
        let next = request.commodityGroupId == "cocoa" && request.page == 1 ? 2 : nil
        return .init(data: data, pagination: .init(pageSize: 2, nextPage: next, previousPage: nil,
            count: request.commodityGroupId == "cocoa" ? 3 : data.count,
            totalPages: request.commodityGroupId == "cocoa" ? 2 : 1, page: request.page))
    }

    func balances(_ request: RequestModels.BalancesList) async throws -> ResponseModels.BalancesInfo {
        if offline { throw RestClient.RestError.connectionLost }
        let json = """
        {"success":true,"data":[{"id":"balance-old","volume":60,
        "commodity":{"id":"beans","code":"1801","name":"Cocoa","unit":"kg","group":{"id":"cocoa","name":"Cocoa"}},
        "harvest_season":{"id":"old","name":"Backend label","start_date":"2025-09-01","end_date":"2026-09-01","status":"past"}}],
        "pagination":{"page":1,"page_size":20,"count":1,"total_pages":1,"next_page":null,"previous_page":null}}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.BalancesInfo.self, from: Data(json.utf8))
    }

    private func season(_ id: String, _ status: ResponseModels.HarvestSeason.Status) -> ResponseModels.HarvestSeason {
        .init(id: id, name: "Backend label", startDate: "2025-09-01", endDate: "2026-09-01", status: status)
    }
}

final class CatalogueOfflineConnectivity: Connectivity {
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> { Just(.notReachable).eraseToAnyPublisher() }
    var isReachableValue: ConnectivityImpl.Status { .notReachable }
    var isReachableFlag: Bool { false }
    func startObserving() { }
    func stopObserving() { }
}

private struct CatalogueUnusedBalance: SeasonalBalanceRepository {
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage {
        throw SeasonalBalanceError.unavailableCache
    }
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        throw SeasonalBalanceError.unavailableCache
    }
}
