//
//  TransactionHistoryRepositoryTests.swift
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
import DatabaseKit
import GRDB
import RestClient
import Targets
import StorageKit
@testable import Whimo

final class TransactionHistoryRepositoryTests: XCTestCase {
    func testExactHistoryReopensOfflineAndCannotBorrowAnotherPairOrAccount() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let target = HistoryTarget()
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        let fetched = try await repository.page(query: query, page: 1, cacheOnly: false)
        XCTAssertEqual(fetched.list.map(\.id), ["remote"])
        XCTAssertFalse(fetched.isCached)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let restored = makeRepository(fixture, target: target, database: reopened)
        target.offline = true
        let cached = try await restored.page(query: query, page: 1, cacheOnly: false)
        XCTAssertEqual(cached.list, fetched.list)
        XCTAssertTrue(cached.isCached)
        for other in [TransactionListQuery(commodityId: "butter", exactSeasonId: "past", newestFirst: true),
                      TransactionListQuery(commodityId: "bean", exactSeasonId: "new", newestFirst: true)] {
            do {
                _ = try await restored.page(query: other, page: 1, cacheOnly: true)
                XCTFail("Another pair has no history snapshot")
            } catch TransactionHistoryError.unavailableCache { }
        }
        fixture.storage.set(UserModel(id: "other-account", username: "Other fixture", gadgets: []), key: .user)
        do {
            _ = try await restored.page(query: query, page: 1, cacheOnly: true)
            XCTFail("Account isolation must apply even without a database flush")
        } catch TransactionHistoryError.unavailableCache { }
    }

    func testKnownEmptyCacheDiffersFromGeneralRecordsMissingPagesAndIncompleteResponse() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let target = HistoryTarget()
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        try await fixture.local().save(historyTransaction("general-cache"))
        do {
            _ = try await repository.page(query: query, page: 1, cacheOnly: true)
            XCTFail("Individual records cannot prove query coverage")
        } catch TransactionHistoryError.unavailableCache { }
        target.response = .init(data: [], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1))
        do {
            _ = try await repository.page(query: query, page: 1, cacheOnly: false)
            XCTFail("Missing claimed rows cannot establish empty history")
        } catch TransactionHistoryError.incompleteResponse { }
        target.response = .init(data: [], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 0, totalPages: 0, page: 1))
        let empty = try await repository.page(query: query, page: 1, cacheOnly: false)
        XCTAssertTrue(empty.list.isEmpty)
        target.offline = true
        let cached = try await repository.page(query: query, page: 1, cacheOnly: false)
        XCTAssertTrue(cached.list.isEmpty)
        XCTAssertTrue(cached.isCached)
        do {
            _ = try await repository.page(query: query, page: 2, cacheOnly: true)
            XCTFail("An uncached page cannot be presented as an empty page")
        } catch TransactionHistoryError.unavailableCache { }
    }

    func testQueuedHistoryRequiresExactPairAndAccountAndPreservesEvidence() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let file = URL(fileURLWithPath: fixture.databasePath + ".geojson")
        let bytes = Data("history-evidence-fixture".utf8)
        try bytes.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        var queued = historyTransaction("queued", created: "2026-05-01T12:00:00.000Z", queued: true)
        queued.persistingData = .onDisk(farmLocationFile: .init(fileURL: file, fileName: "evidence.geojson", mimeType: "application/geo+json"))
        let local = fixture.local()
        for item in [queued, historyTransaction("unassigned", season: nil, queued: true),
                     historyTransaction("other-commodity", commodity: "butter", queued: true),
                     historyTransaction("other-season", season: "new", queued: true),
                     historyTransaction("other-account", account: "someone-else", queued: true)] {
            try await seedQueued(item, fixture: fixture)
        }
        let target = HistoryTarget()
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        let result = try await repository.page(query: query, page: 1, cacheOnly: false)
        XCTAssertEqual(result.list.map(\.id), ["queued", "remote"])
        XCTAssertEqual(result.list.first?.persistingData.state, .onDisk)
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let cached = try await makeRepository(fixture, target: target, database: reopened).page(query: query, page: 1, cacheOnly: true)
        XCTAssertEqual(cached.list.map(\.id), ["queued", "remote"])
        let stored = try await fixture.reopenedLocal().fetchTransaction(by: "queued")
        let storedFile = try XCTUnwrap(stored.persistingData.farmLocationFile)
        XCTAssertEqual(try Data(contentsOf: storedFile.fileURL), bytes)
        XCTAssertEqual(storedFile.fileName, "evidence.geojson")
        let queue = try await local.fetchOnDiskTransactions()
        XCTAssertEqual(queue.count, 5)
        let request = RequestModels.TransactionsList(searchData: TransactionListQueryMapper().toDTO(query))
        let matched = try await local.fetchTransactions(with: request)
        XCTAssertEqual(Set(matched.list.map(\.id)), ["queued", "remote"])
    }

    func testDuplicateRemoteRowsAreDeduplicatedAndPageOneInvalidatesLaterCache() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let target = HistoryTarget()
        let response = try await target.transactionsList(.initial())
        let record = try XCTUnwrap(response.data.first)
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        target.response = .init(data: [record, record], pagination: .init(
            pageSize: 20, nextPage: nil, previousPage: nil, count: 2, totalPages: 1, page: 1))
        let deduplicated = try await repository.page(query: query, page: 1, cacheOnly: false)
        XCTAssertEqual(deduplicated.list.map(\.id), ["remote"])
        target.response = .init(data: [record], pagination: .init(pageSize: 1, nextPage: 2, previousPage: nil, count: 2, totalPages: 2, page: 1))
        _ = try await repository.page(query: query, page: 1, cacheOnly: false)
        let partial = try await repository.page(query: query, page: 1, cacheOnly: true)
        XCTAssertTrue(partial.isCached)
        XCTAssertEqual(partial.nextPage, 2, "A cached first page does not prove the history is complete")
        target.response = .init(data: [record], pagination: .init(pageSize: 1, nextPage: nil, previousPage: 1, count: 2, totalPages: 2, page: 2))
        _ = try await repository.page(query: query, page: 2, cacheOnly: false)
        target.response = .init(data: [], pagination: .init(pageSize: 20, nextPage: nil, previousPage: nil, count: 0, totalPages: 0, page: 1))
        _ = try await repository.page(query: query, page: 1, cacheOnly: false)
        do {
            _ = try await repository.page(query: query, page: 2, cacheOnly: true)
            XCTFail("A fresh first page invalidates older cached pages")
        } catch TransactionHistoryError.unavailableCache { }
        try await fixture.database.flush()
        do {
            _ = try await repository.page(query: query, page: 1, cacheOnly: true)
            XCTFail("Account cleanup includes history snapshots")
        } catch TransactionHistoryError.unavailableCache { }
    }

    @MainActor
    func testAccountChangeDuringRemoteLoadCannotSaveOrReturnPreviousAccountsHistory() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let target = HistoryTarget()
        let response = try await target.transactionsList(.initial())
        target.started = expectation(description: "History requested")
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        let request = Task { try await repository.page(query: query, page: 1, cacheOnly: false) }
        if let started = target.started { await fulfillment(of: [started], timeout: 2) }
        fixture.storage.set(UserModel(id: "other", username: "Other fixture", gadgets: []), key: .user)
        target.pending?.resume(returning: response)
        do {
            _ = try await request.value
            XCTFail("An account transition makes the response obsolete")
        } catch is CancellationError { }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        do {
            _ = try await repository.page(query: query, page: 1, cacheOnly: true)
            XCTFail("The obsolete response must not repopulate the previous account cache")
        } catch TransactionHistoryError.unavailableCache { }
    }

    private func seedQueued(_ item: TransactionModel, fixture: BuyerPersistenceFixture) async throws {
        var node = fixture.mapper.toDatabaseNode(from: item)
        node.transaction.persistingData = .onDisk(farmLocationFile: item.persistingData.farmLocationFile.map {
            .init(fileURL: $0.fileURL, fileName: $0.fileName, mimeType: $0.mimeType)
        })
        let stored = node
        try await fixture.database.save { db in
            try stored.commodity.group.save(db)
            try stored.commodity.commodity.save(db)
            if let seller = stored.seller { try seller.save(db) }
            if let buyer = stored.buyer { try buyer.save(db) }
            try stored.transaction.save(db)
        }
    }

    func testHistoryReadCannotReplaceAQueuedRecordWithTheSameRemoteID() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        try await seedQueued(historyTransaction("remote", queued: true), fixture: fixture)
        let repository = makeRepository(fixture, target: HistoryTarget(), database: fixture.database)
        let result = try await repository.page(query: .init(commodityId: "bean", exactSeasonId: "past", newestFirst: true),
                                               page: 1, cacheOnly: false)
        let retained = try await fixture.local().fetchOnDiskTransactions()
        XCTAssertEqual(retained.map(\.id), ["remote"], "Reading history must not perform queue replacement")
        XCTAssertEqual(result.list.count, 1)
        XCTAssertEqual(result.list.first?.persistingData.state, .onDisk)
    }

    func testFullHistoryReopensAllLoadedPagesAndPreviewCacheCannotProveCompleteness() async throws {
        let fixture = try BuyerPersistenceFixture()
        defer { fixture.storage.clear() }
        fixture.storage.set(UserModel(id: "account", username: "Fixture", gadgets: []), key: .user)
        let target = HistoryTarget()
        let query = TransactionListQuery(commodityId: "bean", exactSeasonId: "past", newestFirst: true)
        let repository = makeRepository(fixture, target: target, database: fixture.database)
        target.response = try paginatedHistory(page: 1)
        let preview = try await CommodityTransactionsInteractorImpl(repository: repository)
            .recent(commodityId: "bean", seasonId: "past", cacheOnly: false)
        XCTAssertEqual(preview.list.count, 3)
        let first = try await repository.page(query: query, page: 1, cacheOnly: true)
        XCTAssertEqual(first.list.count, 20)
        XCTAssertEqual(first.nextPage, 2)
        do {
            _ = try await repository.page(query: query, page: 2, cacheOnly: true)
            XCTFail("A preview snapshot does not prove that page two is loaded or empty")
        } catch TransactionHistoryError.unavailableCache { }
        for page in 2...3 {
            target.response = try paginatedHistory(page: page)
            let result = try await repository.page(query: query, page: page, cacheOnly: false)
            XCTAssertEqual(result.list.count, page == 2 ? 20 : 5)
            XCTAssertEqual(target.request?.searchData.commodityId, "bean")
            XCTAssertEqual(target.request?.searchData.harvestSeasonId, "past")
        }
        let reopened = try DatabaseImpl(writer: DatabaseQueue(path: fixture.databasePath))
        let restored = makeRepository(fixture, target: target, database: reopened)
        var ids: [String] = []
        var next: Int? = 1
        while let page = next {
            let result = try await restored.page(query: query, page: page, cacheOnly: true)
            XCTAssertTrue(result.isCached)
            ids.append(contentsOf: result.list.map(\.id))
            next = result.nextPage
        }
        XCTAssertEqual(ids.count, 45)
        XCTAssertEqual(Set(ids).count, 45)
        XCTAssertEqual(ids.first, "remote-00")
        XCTAssertEqual(ids.last, "remote-44")
        target.response = try paginatedHistory(page: 1)
        _ = try await restored.page(query: query, page: 1, cacheOnly: false)
        do {
            _ = try await restored.page(query: query, page: 2, cacheOnly: true)
            XCTFail("New page one invalidates the old continuation cache")
        } catch TransactionHistoryError.unavailableCache { }
    }

    private func paginatedHistory(page: Int) throws -> ResponseModels.TransactionsInfo {
        let records = ((page - 1) * 20..<min(page * 20, 45)).map { index in
            let id = String(format: "remote-%02d", index)
            let date = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 1_780_000_000 - Double(index) * 86400))
            return """
            {"id":"\(id)","created_at":"\(date)","type":"downstream","status":"pending",
            "action":"buying","volume":12,"is_buying_from_farmer":false,"is_automatic":false,
            "commodity":{"id":"bean","code":"0901","name":"Ripe cherry","unit":"kg","has_recipe":false,
            "group":{"id":"coffee","name":"Coffee"}},"buyer":{"id":"account","username":"Fixture","gadgets":[]},
            "created_by_id":"account","harvest_season":{"id":"past","name":"Coffee 2025/26","start_date":"2025-09-01",
            "end_date":"2026-09-01","status":"past"}}
            """
        }
        let json = """
        {"data":[\(records.joined(separator: ","))],"pagination":{"page":\(page),"page_size":20,"count":45,"total_pages":3,
        "next_page":\(page < 3 ? String(page + 1) : "null"),"previous_page":\(page > 1 ? String(page - 1) : "null")}}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.TransactionsInfo.self, from: Data(json.utf8))
    }

    private func makeRepository(_ fixture: BuyerPersistenceFixture, target: HistoryTarget,
                                database: DatabaseImpl) -> TransactionHistoryRepositoryImpl {
        .init(target: target, database: database, mapper: fixture.mapper,
              queryMapper: TransactionListQueryMapper(), keychainStore: fixture.storage)
    }
}

final class HistoryTarget: TransactionsTarget {
    var offline = false
    var response: ResponseModels.TransactionsInfo?
    var request: RequestModels.TransactionsList?
    var started: XCTestExpectation?
    var pending: CheckedContinuation<ResponseModels.TransactionsInfo, Error>?
    func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo {
        request = model
        if let started {
            return try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                started.fulfill()
            }
        }
        if offline { throw RestClient.RestError.connectionLost }
        if let response { return response }
        let json = """
        {"data":[{"id":"remote","created_at":"2026-01-01T12:00:00.000Z","type":"downstream","status":"pending",
        "action":"buying","volume":12,"is_buying_from_farmer":false,"is_automatic":false,
        "commodity":{"id":"bean","code":"0901","name":"Ripe cherry","unit":"kg","has_recipe":false,
        "group":{"id":"coffee","name":"Coffee"}},"buyer":{"id":"account","username":"Fixture","gadgets":[]},
        "created_by_id":"account","harvest_season":{"id":"past","name":"Coffee 2025/26","start_date":"2025-09-01",
        "end_date":"2026-09-01","status":"past"}}],
        "pagination":{"page":1,"page_size":20,"count":1,"total_pages":1,"next_page":null,"previous_page":null}}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ResponseModels.TransactionsInfo.self, from: Data(json.utf8))
    }
    func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo {
        throw URLError(.unsupportedURL)
    }
    func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo {
        throw URLError(.unsupportedURL)
    }
    func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo {
        throw URLError(.unsupportedURL)
    }
    func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo {
        throw URLError(.unsupportedURL)
    }
    func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo {
        throw URLError(.unsupportedURL)
    }
    func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws -> ResponseModels.UpdateTransactionStatus {
        throw URLError(.unsupportedURL)
    }
    func updateTransactionGeodata(_ model: RequestModels.UpdateTransactionGeodata) async throws {
        throw URLError(.unsupportedURL)
    }
    func downloadGeojson(_ model: RequestModels.DownloadGeojson) async throws -> ResponseModels.DownloadGeojson {
        throw URLError(.unsupportedURL)
    }
    func downloadCSV(_ model: RequestModels.DownloadCSV) async throws -> ResponseModels.DownloadCSV {
        throw URLError(.unsupportedURL)
    }
    func downloadBundle(_ model: RequestModels.DownloadBundle) async throws -> ResponseModels.DownloadBundle {
        throw URLError(.unsupportedURL)
    }
    func requestTransactionGeodata(_ model: RequestModels.RequestTransactionGeodata) async throws -> ResponseModels.RequestTransactionGeodata {
        throw URLError(.unsupportedURL)
    }
    func resendTransactionNotification(_ model: RequestModels.ResendTransactionNotification) async throws -> ResponseModels.ResendTransactionNotification {
        throw URLError(.unsupportedURL)
    }
}
