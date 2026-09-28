//
//  TransactionTraceabilityMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.06.2025.
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

struct TransactionTraceabilityMapper: TransactionTraceabilityMapperProtocol {
    // MARK: - DTO -> Domain
    private func toDomain(from dto: ResponseModels.TransactionTraceability.Traceability) -> TransactionTraceabilityModel.Traceability {
        switch dto {
            case .full(let value):
                .full(value)
            case .partial(let value):
                .partial(value)
            case .conditional(let value):
                .conditional(value)
            case .incomplete(let value):
                .incomplete(value)
        }
    }

    func toDomain(from dto: ResponseModels.TransactionTraceability) -> TransactionTraceabilityModel {
        .init(items: dto.items.map(toDomain))
    }

    // MARK: - Database -> Domain
    private func toDomain(from dbModel: DatabaseKit.TransactionTraceability.Traceability) -> TransactionTraceabilityModel.Traceability {
        switch dbModel {
            case .full(let value):
                .full(value)
            case .partial(let value):
                .partial(value)
            case .conditional(let value):
                .conditional(value)
            case .incomplete(let value):
                .incomplete(value)
        }
    }

    func toDomain(from dbModel: DatabaseKit.TransactionTraceability) -> TransactionTraceabilityModel {
        .init(items: dbModel.items.map(toDomain))
    }

    // MARK: - Domain -> Database
    private func toDatabase(from dModel: TransactionTraceabilityModel.Traceability) -> DatabaseKit.TransactionTraceability.Traceability {
        switch dModel {
            case .full(let value):
                .full(value)
            case .partial(let value):
                .partial(value)
            case .conditional(let value):
                .conditional(value)
            case .incomplete(let value):
                .incomplete(value)
        }
    }

    func toDatabase(from dModel: TransactionTraceabilityModel, transactionId: String) -> DatabaseKit.TransactionTraceability {
        .init(items: dModel.items.map(toDatabase), transactionId: transactionId)
    }
}
