//
//  SeasonalBalanceMapper.swift
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
import RestClient

protocol SeasonalBalanceMapperProtocol {
    func toDomain(_ response: ResponseModels.BalancesInfo, requestedPage: Int) throws -> SeasonalBalancePage
}

struct SeasonalBalanceMapper: SeasonalBalanceMapperProtocol {
    private let seasonMapper: SeasonCatalogueMapperProtocol

    init(seasonMapper: SeasonCatalogueMapperProtocol) { self.seasonMapper = seasonMapper }

    func toDomain(_ response: ResponseModels.BalancesInfo, requestedPage: Int) throws -> SeasonalBalancePage {
        let page = response.pagination
        guard response.success != false, requestedPage > 0, page.page == requestedPage, page.pageSize > 0,
              page.count >= response.data.count, page.totalPages >= 0,
              page.previousPage == (requestedPage == 1 ? nil : requestedPage - 1),
              page.totalPages >= requestedPage || (requestedPage == 1 && page.totalPages == 0 && page.count == .zero),
              page.nextPage == nil || page.nextPage == requestedPage + 1,
              (page.nextPage != nil) == (page.page < page.totalPages),
              response.data.count <= page.pageSize,
              !response.data.isEmpty || page.count == .zero else {
            throw SeasonalBalanceError.incompleteResponse
        }
        let rows = try response.data.map { row -> SeasonalBalance in
            guard row.volume.isFinite else { throw SeasonalBalanceError.incompleteResponse }

            let commodity = row.commodity
            let traceability: TransactionModel.Traceability?
            switch row.traceability {
                case .fullTraceability: traceability = .fullTraceability
                case .conditionalTraceability: traceability = .conditionalTraceability
                case .partialTraceability: traceability = .partialTraceability
                case .incompleteTraceability: traceability = .incompleteTraceability
                case nil: traceability = nil
            }
            return .init(id: row.id, volume: row.volume,
                         commodity: .init(id: commodity.id, code: commodity.code, name: commodity.name, unit: commodity.unit,
                                          group: .init(id: commodity.group.id, name: commodity.group.name)),
                         season: try row.harvestSeason.map { try seasonMapper.toDomain(from: $0) },
                         traceability: traceability, hasRecipe: row.hasRecipe ?? commodity.hasRecipe ?? false)
        }
        guard Set(rows.map(\.id)).count == rows.count else { throw SeasonalBalanceError.incompleteResponse }

        return .init(rows: rows, pagination: .init(pageSize: page.pageSize, nextPage: page.nextPage,
                     previousPage: page.previousPage, count: page.count, totalPages: page.totalPages, page: page.page),
                     message: response.message, success: response.success)
    }
}
