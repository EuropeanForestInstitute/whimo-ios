//
//  MockTransactionsTarget.swift
//  Whimo
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
//
//  MockTransactionsTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 27.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import RestClient

public struct MockTransactionsTarget: TransactionsTarget, MockableTarget {
    public init() {}

    public func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo {
        try await sleepRequest()

        return .init(
            data: [.mock],
            pagination: .init(pageSize: 1, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1)
        )
    }

    public func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo {
        try await sleepRequest()

        return .init(data: .mock)
    }

    public func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo {
        try await sleepRequest()

        return .mock
    }

    public func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo {
        try await sleepRequest()

        return .init(
            data: [.mock],
            pagination: .init(pageSize: 1, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1)
        )
    }

    public func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo {
        try await sleepRequest()

        return .init(data: .mock)
    }

    public func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo {
        try await sleepRequest()

        return .init(data: .mock)
    }

    public func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws {
        try await sleepRequest()
    }

    public func updateTransactionGeodata(_ model: RequestModels.UpdateTransactionGeodata) async throws {
        try await sleepRequest()
    }

    public func downloadGeojson(_ model: RequestModels.DownloadGeojson) async throws -> ResponseModels.DownloadGeojson {
        try await sleepRequest()
        return .mock
    }

    public func downloadCSV(_ model: RequestModels.DownloadCSV) async throws -> ResponseModels.DownloadCSV {
        try await sleepRequest()
        guard let url: URL = .init(string: "path/to/file") else { throw RestClient.RestError.error(message: "Bad Request.") }

        return .init(fileURL: url)
    }

    public func downloadBundle(_ model: RequestModels.DownloadBundle) async throws -> ResponseModels.DownloadBundle {
        try await sleepRequest()
        guard let url: URL = .init(string: "path/to/bundle") else { throw RestClient.RestError.error(message: "Bad Request.") }

        return .init(fileURL: url)
    }

    public func requestTransactionGeodata(_ model: RequestModels.RequestTransactionGeodata) async throws -> ResponseModels.RequestTransactionGeodata {
        try await sleepRequest()

        return .init(message: "Missing geodata requested")
    }

    public func resendTransactionNotification(
        _ model: RequestModels.ResendTransactionNotification
    ) async throws -> ResponseModels.ResendTransactionNotification {
        try await sleepRequest()

        return .init(message: "Transaction notification resent", success: true)
    }
}

private extension ResponseModels.Transaction {
    static let mock: Self = .init(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        createdAt: "2025-05-27T11:17:35.614Z",
        expiresAt: nil,
        updatedAt: "2025-05-27T11:17:35.614Z",
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: .fullTraceability,
        location: .qrCode,
        farmLatitude: 0.1,
        farmLongitude: 0.1,
        transactionLatitude: nil,
        transactionLongitude: nil,
        commodity: .mock,
        volume: 300,
        isBuyingFromFarmer: false,
        isAutomatic: false,
        seller: nil,
        buyer: .init(
            id: "c3a55629-7b32-4e42-afdc-abcec85e1815",
            username: "natural-misty-lion-894e80",
            gadgets: [
                .init(
                    id: "d2a63cb0-81ba-4722-8577-b785f8a610c4",
                    identifier: "test.email@gmail.com",
                    type: .email,
                    isVerified: true
                )
            ]
        ),
        createdById: "c3a55629-7b32-4e42-afdc-abcec85e1815"
    )
}

private extension ResponseModels.Commodity {
    static let mock: Self = .init(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        code: "1801",
        name: "Cocoa beans, whole or broken, raw or roasted",
        unit: "kg",
        group: .init(
            id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            name: "Cocoa"
        )
    )
}

private extension ResponseModels.TransactionTraceabilityInfo {
    static let mock: Self = .init(
        data: .init(
            items: [
                .full(0),
                .partial(0),
                .conditional(0),
                .incomplete(0)
            ]
        )
    )
}

private extension ResponseModels.SupplierTransaction {
    static let mock: Self = .init(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        createdAt: "2025-05-27T11:17:35.614Z",
        type: .producer,
        status: .accepted,
        traceability: .fullTraceability,
        location: .qrCode,
        latitude: 0.1,
        longitude: 0.1,
        commodity: .mock,
        volume: 300,
        isBuyingFromFarmer: false,
        isAutomatic: false,
        seller: nil,
        buyer: .init(
            id: "c3a55629-7b32-4e42-afdc-abcec85e1815",
            username: "natural-misty-lion-894e80",
            gadgets: [
                .init(
                    id: "d2a63cb0-81ba-4722-8577-b785f8a610c4",
                    identifier: "test.email@gmail.com",
                    type: .email,
                    isVerified: true
                )
            ]
        ),
        createdById: "c3a55629-7b32-4e42-afdc-abcec85e1815"
    )

}

private extension ResponseModels.DownloadGeojson {
    static let mock: Self = .init(
        data: .init(
            featureCollection: .init(
                type: .featureCollection,
                features: [
                    .init(
                        type: .feature,
                        id: .zero,
                        geometry: .init(
                            coordinates: [
                                [
                                    [11.145107996769699, 4.092248996494226],
                                    [11.144893993125184, 4.092050995522071]
                                ]
                            ]
                        ),
                        properties: .init(
                            producerName: "Producer 1",
                            producerCountry: "US",
                            productionPlace: "place 1"
                        )
                    )
                ]
            )
        )
    )
}
