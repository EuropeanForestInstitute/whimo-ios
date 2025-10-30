//
//  CommoditiesMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 01.06.2025.
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

struct CommoditiesMapper: CommoditiesMapperProtocol {
    // MARK: - DTO -> Domain
    private func toDomain(from dto: ResponseModels.Commodity.Group) -> CommodityModel.Group {
        .init(id: dto.id, name: dto.name)
    }

    func toDomain(from dto: ResponseModels.Commodity) -> CommodityModel {
        .init(
            id: dto.id,
            code: dto.code,
            name: dto.name,
            unit: dto.unit,
            group: toDomain(from: dto.group)
        )
    }

    // MARK: - Database -> Domain
    func toDomain(from dbModel: DatabaseKit.Commodity) -> CommodityGroupModel.Commodity {
        .init(
            id: dbModel.id,
            code: dbModel.code,
            name: dbModel.name,
            unit: dbModel.unit,
            balance: dbModel.balance
        )
    }

    private func toDomain(from dbModel: DatabaseKit.CommodityGroup) -> CommodityModel.Group {
        .init(id: dbModel.id, name: dbModel.name)
    }

    func toDomain(from dbModel: DatabaseKit.Commodity.Node) -> CommodityModel {
        .init(
            id: dbModel.commodity.id,
            code: dbModel.commodity.code,
            name: dbModel.commodity.name,
            unit: dbModel.commodity.unit,
            group: toDomain(from: dbModel.group)
        )
    }

    // MARK: - Domain -> Database
    func toDatabase(from dModel: CommodityModel.Group) -> DatabaseKit.CommodityGroup {
        .init(id: dModel.id, name: dModel.name)
    }

    func toDatabase(from dModel: CommodityModel) -> DatabaseKit.Commodity {
        .init(
            id: dModel.id,
            code: dModel.code,
            name: dModel.name,
            unit: dModel.unit,
            balance: nil,
            commodityGroupId: dModel.group.id
        )
    }
}
