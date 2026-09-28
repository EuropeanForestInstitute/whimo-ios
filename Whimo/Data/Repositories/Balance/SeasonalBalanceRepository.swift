//
//  SeasonalBalanceRepository.swift
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

protocol SeasonalBalanceRepository {
    func page(query: BalanceListQuery, page: Int, cacheOnly: Bool) async throws -> SeasonalBalancePage
    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance
    func exact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance
}

// Default for substitutes; production resolves the latest persisted observation across queries.
extension SeasonalBalanceRepository {
    func cachedExact(commodityId: String, seasonId: String) async throws -> ExactSeasonalBalance {
        var result = try await page(query: .init(commodityId: commodityId, exactSeasonId: seasonId), page: 1, cacheOnly: true)
        result.isCached = true
        return try result.exactBalance(commodityId: commodityId, seasonId: seasonId)
    }
}

extension SeasonalBalancePage {
    func exactBalance(commodityId: String, seasonId: String) throws -> ExactSeasonalBalance {
        guard !commodityId.isEmpty, !seasonId.isEmpty, success != false,
              pagination.page == 1, pagination.previousPage == nil, pagination.nextPage == nil,
              pagination.pageSize > 0, rows.count <= pagination.pageSize, rows.count == pagination.count,
              pagination.totalPages == 1 || (rows.isEmpty && pagination.totalPages == 0), rows.count <= 1, rows.allSatisfy({
                  $0.commodity.id == commodityId && $0.season?.id == seasonId && $0.volume.isFinite && $0.volume >= 0
              }) else { throw SeasonalBalanceError.incompleteResponse }

        return .init(volume: rows.first?.volume ?? 0, traceability: rows.first?.traceability, isCached: isCached)
    }
}
