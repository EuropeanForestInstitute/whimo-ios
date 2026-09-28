//
//  ConvertCommodityInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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
import RestClient
import Utility

final class ConvertCommodityInteractorImpl: ConvertCommodityInteractor {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let commodityConversionRemoteRepository: CommodityConversionRemoteRepository

    // MARK: - Init
    init(commodityConversionRemoteRepository: CommodityConversionRemoteRepository,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.commodityConversionRemoteRepository = commodityConversionRemoteRepository
    }

    // MARK: - ConvertCommodityInteractor
    func fetchConversationRule(
        commodity: CommodityGroupModel.Commodity,
        oldPagination: ConversionPagination?,
        refresh: Bool
    ) async throws -> (list: IdentifiedArrayOf<ConversionRuleModel>, pagination: ConversionPagination) {
        try await businessDataContext.withCurrentGeneration {
            let pagination: ConversionPagination

            if !refresh, let oldPagination {
                pagination = .init(
                    commodityId: commodity.id,
                    pageData: .init(
                        page: oldPagination.pageData.page + 1,
                        pageSize: oldPagination.pageData.pageSize
                    )
                )
            } else {
                pagination = .initial(commodityId: commodity.id)
            }

            let responseData = try await commodityConversionRemoteRepository.getConversionRules(pagination)
            let updatedPageData: PaginationRequest = .init(
                page: responseData.pagination.nextPage == nil ? oldPagination?.pageData.page ?? PaginationRequest.initial.page : pagination.pageData.page,
                pageSize: pagination.pageData.pageSize
            )
            var updatedPagination: ConversionPagination = .init(
                commodityId: commodity.id,
                pageData: updatedPageData
            )
            updatedPagination.nextPage = responseData.pagination.nextPage

            return (responseData.list, updatedPagination)
        }
    }

    func makeConversion(
        rule: ConversionRuleModel,
        seasonId: String,
        inputOverrides: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>,
        outputCommodities: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>
    ) async throws {
        try await businessDataContext.withProtectedWork {
            let commodityIds = Set((rule.inputs + rule.outputs).map { $0.commodity.id })
            guard !seasonId.isEmpty, !commodityIds.isEmpty, !commodityIds.contains("") else {
                throw ConversionError.coverage
            }
            guard try await commodityConversionRemoteRepository.coversSeason(seasonId, commodityIds: commodityIds.sorted()) else {
                throw ConversionError.coverage
            }

            try businessDataContext.capture().check()
            try await commodityConversionRemoteRepository.makeConversion(
                recipeId: rule.id,
                seasonId: seasonId,
                inputOverrides: inputOverrides,
                outputOverrides: outputCommodities
            )
        }
    }
}
