//
//  CommodityConversionRemoteRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
//
//  Copyright (c) 2025 EFI https://efi.int/
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
import Targets
import RestClient
import typealias Utility.IdentifiedArrayOf

final class CommodityConversionRemoteRepositoryImpl: CommodityConversionRemoteRepository {
    // MARK: - Dependencies
    private let seasonsTarget: HarvestSeasonsTarget
    private let commodityConversionTarget: CommodityConversionTarget
    private let commodityConversionMapper: CommodityConversionMapperProtocol

    // MARK: - Init
    init(
        commodityConversionTarget: CommodityConversionTarget,
        commodityConversionMapper: CommodityConversionMapperProtocol,
        seasonsTarget: HarvestSeasonsTarget
    ) {
        self.seasonsTarget = seasonsTarget
        self.commodityConversionTarget = commodityConversionTarget
        self.commodityConversionMapper = commodityConversionMapper
    }

    // MARK: - CommodityConversionRemoteRepository
    func coversSeason(_ seasonId: String, commodityIds: [String]) async throws -> Bool {
        var page = 1
        while true {
            try Task.checkCancellation()
            try BusinessDataContext.requestGeneration?.check()
            let response = try await seasonsTarget.seasons(.init(commodityIds: commodityIds, page: page))
            try BusinessDataContext.requestGeneration?.check()
            if response.data.contains(where: { $0.id == seasonId }) { return true }
            guard let next = response.pagination.nextPage else { return false }
            guard next > page else { throw ConversionError.unavailable }

            page = next
        }
    }

    func getConversionRules(_ model: ConversionPagination) async throws -> ConversionData {
        let response = try await commodityConversionTarget.getConversionRules(model)
        let conversionRulesList = response
            .data
            .map(commodityConversionMapper.toDomain)

        return (.init(uniqueElements: conversionRulesList), response.pagination)
    }

    func makeConversion(
        recipeId: String,
        seasonId: String,
        inputOverrides: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>,
        outputOverrides: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>
    ) async throws {
        let inputOverridesRequest: [RequestModels.MakeConversion.Override] = inputOverrides.map { item in
            .init(commodityId: item.commodity.id, quantity: item.quantity)
        }

        let outputOverridesRequest: [RequestModels.MakeConversion.Override] = outputOverrides.map { item in
            .init(commodityId: item.commodity.id, quantity: item.quantity)
        }

        let requestModel: RequestModels.MakeConversion = .init(
            recipeId: recipeId,
            harvestSeasonId: seasonId,
            inputOverrides: inputOverridesRequest,
            outputOverrides: outputOverridesRequest
        )

        do {
            try await commodityConversionTarget.makeConversion(requestModel)
        } catch RestClient.RestError.clientError(_, .conflict, _) {
            throw ConversionError.insufficientBalance
        } catch RestClient.RestError.clientError(_, .badRequest, _) {
            throw ConversionError.coverage
        }
    }
}
