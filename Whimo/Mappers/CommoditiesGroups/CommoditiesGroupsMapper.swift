//
//  CommoditiesGroupsMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 31.05.2025.
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
import DatabaseKit
import RestClient

// MARK: - CommoditiesGroupsMapper
struct CommoditiesGroupsMapper: CommoditiesGroupsMapperProtocol {
    // MARK: - Dependencies
    private let commoditiesMapper: CommoditiesMapperProtocol

    // MARK: - Init
    init(commoditiesMapper: CommoditiesMapperProtocol) {
        self.commoditiesMapper = commoditiesMapper
    }

    // MARK: - DTO -> Domain
    private func toDomain(from dto: ResponseModels.CommodityGroup.Commodity) -> CommodityGroupModel.Commodity {
        .init(
            id: dto.id,
            code: dto.code,
            name: dto.name,
            unit: dto.unit,
            balance: dto.balance
        )
    }

    func toDomain(from dto: ResponseModels.CommodityGroup) -> CommodityGroupModel {
        .init(
            id: dto.id,
            name: dto.name,
            commodities: dto.commodities.map(toDomain(from:))
        )
    }

    // MARK: - Database -> Domain
    func toDomain(from dbModel: DatabaseKit.CommodityGroup.Node) -> CommodityGroupModel {
        .init(
            id: dbModel.commodityGroup.id,
            name: dbModel.commodityGroup.name,
            commodities: dbModel.commodities.map(commoditiesMapper.toDomain)
        )
    }

    // MARK: - Domain -> Database
    func toDatabase(from dModel: CommodityGroupModel.Commodity, parrentId: String) -> DatabaseKit.Commodity {
        .init(
            id: dModel.id,
            code: dModel.code,
            name: dModel.name,
            unit: dModel.unit,
            balance: dModel.balance,
            commodityGroupId: parrentId
        )
    }

    func toDatabase(from dModel: CommodityGroupModel) -> DatabaseKit.CommodityGroup {
        .init(id: dModel.id, name: dModel.name)
    }
}
