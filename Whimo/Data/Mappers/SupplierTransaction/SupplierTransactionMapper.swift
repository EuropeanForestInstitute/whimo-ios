//
//  SupplierTransactionMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.06.2025.
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

// MARK: - TransactionsMapper
struct SupplierTransactionMapper: SupplierTransactionMapperProtocol {
    // MARK: - Dependencies
    private let commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol
    private let userMapper: UserMapperProtocol

    // MARK: - Init
    init(commoditiesGroupsMapper: CommoditiesGroupsMapperProtocol, userMapper: UserMapperProtocol) {
        self.commoditiesGroupsMapper = commoditiesGroupsMapper
        self.userMapper = userMapper
    }

    // MARK: - SupplierTransactionMapperProtocol
    private func toDomain(from dto: ResponseModels.Transaction.TransactionType) -> TransactionModel.TransactionType {
        switch dto {
            case .producer:
                return .producer
            case .downstream:
                return .downstream
            case .conversion:
                return .conversion
        }
    }

    private func toDomain(from dto: ResponseModels.SupplierTransaction) -> TransactionModel.Status {
        if dto.isAutomatic {
            return .automatic
        }

        if !dto.isAutomatic && dto.type == .producer {
            return .recorded
        }

        switch dto.status {
            case .accepted:
                return .accepted
            case .rejected:
                return .rejected
            case .pending:
                return .pending
            case .noResponse:
                return .noResponse
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction.Traceability?) -> TransactionModel.Traceability? {
        switch dto {
            case .fullTraceability:
                .fullTraceability
            case .conditionalTraceability:
                .conditionalTraceability
            case .partialTraceability:
                .partialTraceability
            case .incompleteTraceability:
                .incompleteTraceability
            case .none:
                nil
        }
    }

    private func toDomain(from dto: ResponseModels.Transaction.LocationType?) -> TransactionModel.LocationType? {
        switch dto {
            case .qrCode:
                .qrCode
            case .manual:
                .manual
            case .file:
                .file
            case .gps:
                .gps
            case .none:
                nil
        }
    }

    func toDomain(from dto: ResponseModels.SupplierTransaction) -> SupplierTransactionModel {
        .init(
            id: dto.id,
            createdAt: dto.createdAt,
            type: toDomain(from: dto.type),
            status: toDomain(from: dto),
            traceability: toDomain(from: dto.traceability),
            location: toDomain(from: dto.location),
            latitude: dto.latitude,
            longitude: dto.longitude,
            volume: dto.volume,
            isBuyingFromFarmer: dto.isBuyingFromFarmer,
            commodity: commoditiesGroupsMapper.toDomain(from: dto.commodity),
            seller: userMapper.toDomainOptional(dto: dto.seller),
            buyer: userMapper.toDomainOptional(dto: dto.buyer),
            createdById: dto.createdById
        )
    }
}
