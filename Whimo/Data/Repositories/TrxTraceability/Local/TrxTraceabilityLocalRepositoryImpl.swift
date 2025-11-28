//
//  TrxTraceabilityLocalRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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

// MARK: - TrxTraceabilityLocalRepositoryImpl
final class TrxTraceabilityLocalRepositoryImpl: TrxTraceabilityLocalRepository {
    // MARK: - Error
    enum Error: LocalizedError {
        case failedReadObject(objectId: String)

        public var errorDescription: String? {
            switch self {
                case .failedReadObject(let objectId):
                    return "Failed read object. Object ID: \(objectId)"
            }
        }
    }
    // MARK: - Dependencies
    private let database: DatabaseKit.Database
    private let transactionTraceabilityMapper: TransactionTraceabilityMapperProtocol

    // MARK: - Init
    init(
        database: DatabaseKit.Database,
        transactionTraceabilityMapper: TransactionTraceabilityMapperProtocol
    ) {
        self.database = database
        self.transactionTraceabilityMapper = transactionTraceabilityMapper
    }

    // MARK: - TrxTraceabilityLocalRepository
    func fetchTransactionTraceability(by id: String) async throws -> TransactionTraceabilityModel {
        guard
            let dbModel = try await database.readOne(
                DatabaseKit.TransactionTraceability.Node
                    .byID(id)
            )
        else { throw Error.failedReadObject(objectId: id) }

        let domainModel = transactionTraceabilityMapper.toDomain(from: dbModel.transactionTraceability)
        return domainModel
    }

    func save(
        _ traceability: TransactionTraceabilityModel,
        transactionId: String
    ) async throws {
        let transactionTraceability = transactionTraceabilityMapper.toDatabase(
            from: traceability,
            transactionId: transactionId
        )

        try await database.save(transactionTraceability)
    }
}
