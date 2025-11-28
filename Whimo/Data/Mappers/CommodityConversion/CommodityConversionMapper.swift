//
//  CommodityConversionMapper.swift
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
import RestClient

struct CommodityConversionMapper: CommodityConversionMapperProtocol {
    // MARK: - Dependencies
    private let commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol

    // MARK: - Init
    init(commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol) {
        self.commoditiesGroupsMapper = commoditiesGroupsMapper
    }

    // MARK: - DTO -> Domain
    private func toDomain(dto: ResponseModels.Rule.RuleItem) -> ConversionRuleModel.ConversionRuleItem {
        .init(
            id: dto.id,
            commodity: commoditiesGroupsMapper.toDomain(from: dto.commodity),
            quantity: dto.quantity
        )
    }

    func toDomain(dto: ResponseModels.Rule) -> ConversionRuleModel {
        .init(
            id: dto.id,
            name: dto.name,
            inputs: dto.inputs.map(toDomain(dto:)),
            outputs: dto.outputs.map(toDomain(dto:))
        )
    }
    // MARK: - Database -> Domain
    // MARK: - Domain -> Database
}
