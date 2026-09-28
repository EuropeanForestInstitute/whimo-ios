//
//  SeasonalBalance.swift
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

struct BalanceListQuery: Equatable {
    var search = ""
    var filter = CommoditySeasonFilter()
    var commodityId: String?
    var exactSeasonId: String?
}

struct SeasonalBalance: Identifiable, Equatable, Codable {
    let id: String
    let volume: Double
    let commodity: Commodity
    let season: HarvestSeason?
    let traceability: TransactionModel.Traceability?
    let hasRecipe: Bool

    struct Commodity: Equatable, Codable {
        let id: String
        let code: String
        let name: String
        let unit: String
        let group: CatalogueGroup
    }

    var conversionCommodity: CommodityGroupModel.Commodity {
        .init(id: commodity.id, code: commodity.code, name: commodity.name, unit: commodity.unit,
              balance: volume, hasRecipe: hasRecipe, group: .init(id: commodity.group.id, name: commodity.group.name))
    }
}

struct BalancePagination: Equatable, Codable {
    let pageSize: Int
    let nextPage: Int?
    let previousPage: Int?
    let count: Int
    let totalPages: Int
    let page: Int
}

struct SeasonalBalancePage: Equatable, Codable {
    let rows: [SeasonalBalance]
    let pagination: BalancePagination
    let message: String?
    let success: Bool?
    var isCached = false
}

struct ExactSeasonalBalance: Equatable {
    let volume: Double
    let traceability: TransactionModel.Traceability?
    let isCached: Bool
}

enum SeasonalBalanceError: Error {
    case unavailableCache
    case incompleteResponse
}
