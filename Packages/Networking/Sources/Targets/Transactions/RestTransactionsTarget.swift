//
//  RestTransactionsTarget.swift
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
//  RestTransactionsTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 27.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Networking
import RestClient

public struct RestTransactionsTarget: AnyNetworkTarget {
    public let restClient: any RestClientProtocol

    public init(restClient: any RestClientProtocol) {
        self.restClient = restClient
    }
}

extension RestTransactionsTarget: TransactionsTarget {
    public func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo {
        try await restClient.makeRequest(RequestRouter.Transactions.transactionsList(model))
    }

    public func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo {
        try await restClient.makeRequest(RequestRouter.Transactions.getTransaction(model))
    }

    public func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo {
        try await restClient.makeRequest(RequestRouter.Transactions.getTransactionTraceability(model))
    }

    public func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo {
        try await restClient.makeRequest(RequestRouter.Transactions.transactionsList(model))
    }

    public func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo {
        let request = RequestRouter.CreateTransaction.createProducer(model)
        let accessibleURLs = request.uploadData
            .map { uploadData in
                switch uploadData {
                    case .file(let fileMultipartEncodable):
                        return fileMultipartEncodable.fileURL
                    case .data:
                        return nil
                }
            }
            .compactMap { $0 }
            .filter { $0.startAccessingSecurityScopedResource() }

        defer {
            for url in accessibleURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await restClient.makeMultipartRequest(request)
    }

    public func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo {
        let request = RequestRouter.CreateTransaction.createDownstream(model)
        let accessibleURLs = request.uploadData
            .map { uploadData in
                switch uploadData {
                    case .file(let fileMultipartEncodable):
                        return fileMultipartEncodable.fileURL
                    case .data:
                        return nil
                }
            }
            .compactMap { $0 }
            .filter { $0.startAccessingSecurityScopedResource() }

        defer {
            for url in accessibleURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await restClient.makeMultipartRequest(request)
    }

    public func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Transactions.updateTransaction(model))
    }

    public func updateTransactionGeodata(_ model: RequestModels.UpdateTransactionGeodata) async throws {
        let request = RequestRouter.CreateTransaction.updateTransactionGeodata(model)
        let accessibleURLs = request.uploadData
            .map { uploadData in
                switch uploadData {
                    case .file(let fileMultipartEncodable):
                        return fileMultipartEncodable.fileURL
                    case .data:
                        return nil
                }
            }
            .compactMap { $0 }
            .filter { $0.startAccessingSecurityScopedResource() }

        defer {
            for url in accessibleURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let _: VoidResponse = try await restClient.makeMultipartRequest(request)
    }

    public func downloadGeojson(_ model: RequestModels.DownloadGeojson) async throws -> ResponseModels.DownloadGeojson {
        try await restClient.makeRequest(RequestRouter.Transactions.downloadGeojson(model))
    }

    public func downloadCSV(_ model: RequestModels.DownloadCSV) async throws -> ResponseModels.DownloadCSV {
        let fileURL = try await restClient.downloadRequest(
            RequestRouter.Transactions.downloadCSV(model),
            to: nil,
        )
        guard let fileURL else {
            throw RestClient.RestError.error(message: "Bad Response. Cannot perform download request.")
        }

        let model: ResponseModels.DownloadCSV = .init(fileURL: fileURL)
        return model
    }

    public func downloadBundle(_ model: RequestModels.DownloadBundle) async throws -> ResponseModels.DownloadBundle {
        let fileURL = try await restClient.downloadRequest(
            RequestRouter.Transactions.downloadBundle(model),
            to: nil,
        )
        guard let fileURL else {
            throw RestClient.RestError.error(message: "Bad Response. Cannot perform download request.")
        }

        let responseModel: ResponseModels.DownloadBundle = .init(fileURL: fileURL)
        return responseModel
    }

    public func requestTransactionGeodata(
        _ model: RequestModels.RequestTransactionGeodata
    ) async throws -> ResponseModels.RequestTransactionGeodata {
        try await restClient.makeRequest(RequestRouter.Transactions.requestTransactionGeodata(model))
    }

    public func resendTransactionNotification(
        _ model: RequestModels.ResendTransactionNotification
    ) async throws -> ResponseModels.ResendTransactionNotification {
        try await restClient.makeRequest(RequestRouter.Transactions.resendTransactionNotification(model))
    }
}
