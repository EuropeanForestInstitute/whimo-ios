//
//  CommodityTransactionsInteractor.swift
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

import Foundation
import Utility

protocol CommodityTransactionsInteractor {
    func page(commodityId: String, seasonId: String, page: Int, cacheOnly: Bool) async throws -> TransactionListPage
    func recent(commodityId: String, seasonId: String, cacheOnly: Bool) async throws -> TransactionListPage
}

struct CommodityTransactionsInteractorImpl: CommodityTransactionsInteractor {
    let repository: TransactionListRepository

    func recent(commodityId: String, seasonId: String, cacheOnly: Bool) async throws -> TransactionListPage {
        let result = try await page(commodityId: commodityId, seasonId: seasonId, page: 1, cacheOnly: cacheOnly)
        return .init(list: .init(uniqueElements: result.list.prefix(3)), nextPage: result.nextPage, isCached: result.isCached)
    }

    func page(commodityId: String, seasonId: String, page: Int, cacheOnly: Bool) async throws -> TransactionListPage {
        let query = TransactionListQuery(commodityId: commodityId, exactSeasonId: seasonId, newestFirst: true)
        let result = try await repository.page(query: query, page: page, cacheOnly: cacheOnly)
        let matching = TransactionListQuery.creationOrder(result.list.filter(query.matches))
        return .init(list: .init(uniqueElements: matching), nextPage: result.nextPage, isCached: result.isCached)
    }
}

enum TransactionHistoryError: Error {
    case unavailableCache
    case incompleteResponse
    case invalidQuery
    case loadFailed
}
