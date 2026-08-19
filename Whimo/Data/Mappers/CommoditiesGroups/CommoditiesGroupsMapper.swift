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
    // MARK: - DTO -> Domain
    func toDomain(from dto: ResponseModels.CommodityGroup.Commodity) -> CommodityGroupModel.Commodity {
        if let hasRecipe = dto.hasRecipe {
            return .init(
                id: dto.id,
                code: dto.code,
                name: dto.name,
                unit: dto.unit,
                balance: dto.balance,
                hasRecipe: hasRecipe,
                group: .init(id: dto.group.id, name: dto.group.name)
            )
        } else {
            return .init(
                id: dto.id,
                code: dto.code,
                name: dto.name,
                unit: dto.unit,
                balance: dto.balance,
                hasRecipe: false,
                group: .init(id: dto.group.id, name: dto.group.name)
            )
        }
    }

    func toDomain(from dto: ResponseModels.CommodityGroup) -> CommodityGroupModel {
        .init(
            id: dto.id,
            name: dto.name,
            commodities: dto.commodities.map { toDomain(from: $0) }
        )
    }

    // MARK: - Database -> Domain
    func toDomain(from dbModel: DatabaseKit.Commodity.Node) -> CommodityGroupModel.Commodity {
        .init(
            id: dbModel.commodity.id,
            code: dbModel.commodity.code,
            name: dbModel.commodity.name,
            unit: dbModel.commodity.unit,
            balance: dbModel.commodity.balance,
            hasRecipe: dbModel.commodity.hasRecipe,
            group: .init(id: dbModel.group.id, name: dbModel.group.name)
        )
    }

    private func toDomain(dbCommodityGroup: DatabaseKit.CommodityGroup, dbCommodity: DatabaseKit.Commodity) -> CommodityGroupModel.Commodity {
        .init(
            id: dbCommodity.id,
            code: dbCommodity.code,
            name: dbCommodity.name,
            unit: dbCommodity.unit,
            balance: dbCommodity.balance,
            hasRecipe: dbCommodity.hasRecipe,
            group: .init(id: dbCommodityGroup.id, name: dbCommodityGroup.name)
        )
    }

    func toDomain(from dbModel: DatabaseKit.CommodityGroup.Node) -> CommodityGroupModel {
        .init(
            id: dbModel.commodityGroup.id,
            name: dbModel.commodityGroup.name,
            commodities: dbModel.commodities.map({ toDomain(dbCommodityGroup: dbModel.commodityGroup, dbCommodity: $0) })
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
            commodityGroupId: parrentId,
            hasRecipe: dModel.hasRecipe
        )
    }

    func toDatabase(from dModel: CommodityGroupModel.Commodity.Group) -> DatabaseKit.CommodityGroup {
        .init(id: dModel.id, name: dModel.name)
    }

    func toDatabase(from dModel: CommodityGroupModel) -> DatabaseKit.CommodityGroup {
        .init(id: dModel.id, name: dModel.name)
    }
}
