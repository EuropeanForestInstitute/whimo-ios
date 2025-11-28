//
//  TransactionsTarget.swift
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
//  TransactionsTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 27.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Alamofire
import Networking
import RestClient

public protocol TransactionsTarget {
    func transactionsList(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.TransactionsInfo
    func getTransaction(_ model: RequestModels.GetTransaction) async throws -> ResponseModels.TransactionInfo
    func getSuppliersTransaction(_ model: RequestModels.TransactionsList) async throws -> ResponseModels.SupplierTransactionsInfo
    func getTransactionTraceability(_ model: RequestModels.GetTransactionTraceability) async throws -> ResponseModels.TransactionTraceabilityInfo
    func createProducerTransaction(_ model: RequestModels.CreateTransaction.Producer) async throws -> ResponseModels.TransactionInfo
    func createDownstreamTransaction(_ model: RequestModels.CreateTransaction.Downstream) async throws -> ResponseModels.TransactionInfo
    func updateTransaction(_ model: RequestModels.UpdateTransactionStatus) async throws
    func updateTransactionGeodata(_ model: RequestModels.UpdateTransactionGeodata) async throws
    func downloadGeojson(_ model: RequestModels.DownloadGeojson) async throws -> ResponseModels.DownloadGeojson
    func downloadCSV(_ model: RequestModels.DownloadCSV) async throws -> ResponseModels.DownloadCSV
    func downloadBundle(_ model: RequestModels.DownloadBundle) async throws -> ResponseModels.DownloadBundle
    func requestTransactionGeodata(_ model: RequestModels.RequestTransactionGeodata) async throws -> ResponseModels.RequestTransactionGeodata
    func resendTransactionNotification(_ model: RequestModels.ResendTransactionNotification) async throws -> ResponseModels.ResendTransactionNotification
}

extension RequestRouter {
    // MARK: - Transactions
    public enum Transactions {
        case transactionsList(RequestModels.TransactionsList)
        case getTransaction(RequestModels.GetTransaction)
        case updateTransaction(RequestModels.UpdateTransactionStatus)
        case getTransactionTraceability(RequestModels.GetTransactionTraceability)
        case downloadGeojson(RequestModels.DownloadGeojson)
        case downloadCSV(RequestModels.DownloadCSV)
        case downloadBundle(RequestModels.DownloadBundle)
        case requestTransactionGeodata(RequestModels.RequestTransactionGeodata)
        case resendTransactionNotification(RequestModels.ResendTransactionNotification)
    }

    // MARK: - CreateTransaction
    public enum CreateTransaction {
        case createProducer(RequestModels.CreateTransaction.Producer)
        case createDownstream(RequestModels.CreateTransaction.Downstream)
        case updateTransactionGeodata(RequestModels.UpdateTransactionGeodata)
    }
}

// MARK: - RequestRouter+Transactions
extension RequestRouter.Transactions: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .transactionsList:
                "/transactions/"
            case .getTransaction(let data):
                "/transactions/\(data.transactionId)/"
            case .updateTransaction(let data):
                "/transactions/\(data.transactionId)/status/"
            case .getTransactionTraceability(let data):
                "/transactions/\(data.transactionId)/traceability-counts/"
            case .downloadGeojson(let data):
                "/transactions/\(data.transactionId)/download/geojson/"
            case .requestTransactionGeodata(let data):
                "/transactions/\(data.transactionId)/geodata/request/"
            case .resendTransactionNotification(let data):
                "/transactions/\(data.transactionId)/notification/resend/"
            case .downloadCSV(let data):
                "/transactions/\(data.transactionId)/download/csv/"
            case .downloadBundle(let data):
                "/transactions/\(data.transactionId)/download/bundle/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .transactionsList:
                .get
            case .getTransaction:
                .get
            case .updateTransaction:
                .patch
            case .getTransactionTraceability:
                .get
            case .downloadGeojson:
                .get
            case .requestTransactionGeodata:
                .post
            case .resendTransactionNotification:
                .post
            case .downloadCSV:
                .get
            case .downloadBundle:
                .get
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .transactionsList(let data):
                data
            case .getTransaction:
                nil
            case .updateTransaction(let data):
                data
            case .getTransactionTraceability:
                nil
            case .downloadGeojson:
                nil
            case .requestTransactionGeodata:
                nil
            case .resendTransactionNotification:
                nil
            case .downloadCSV:
                nil
            case .downloadBundle:
                nil
        }
    }

    public var addAuth: Bool {
        switch self {
            case .transactionsList, .getTransaction,
                 .updateTransaction, .getTransactionTraceability,
                 .downloadGeojson, .requestTransactionGeodata,
                 .resendTransactionNotification, .downloadCSV, .downloadBundle:
                true
        }
    }
}

// MARK: - RequestRouter+CreateTransaction
extension RequestRouter.CreateTransaction: AnyUploadNetworkRouter {
    public var uploadData: [MultipartUpload] {
        switch self {
            case .createProducer(let data):
                var uploadData: [MultipartUpload] = [.data(data.transactionData)]

                if let uploadFile = data.uploadFile {
                    uploadData.append(.file(uploadFile))
                }

                return uploadData
            case .createDownstream(let data):
                var uploadData: [MultipartUpload] = [.data(data.transactionData)]

                if let uploadFile = data.uploadFile {
                    uploadData.append(.file(uploadFile))
                }

                return uploadData
            case .updateTransactionGeodata(let data):
                return [
                    .data(data.transactionData),
                    .file(data.uploadFile)
                ]
        }
    }

    public var path: Endpoint {
        switch self {
            case .createProducer:
                "/transactions/producer/"
            case .createDownstream:
                "/transactions/downstream/"
            case .updateTransactionGeodata(let data):
                "/transactions/\(data.transactionId)/geodata/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .createProducer, .createDownstream:
                .post
            case .updateTransactionGeodata:
                .patch
        }
    }

    public var addAuth: Bool {
        switch self {
            case .createProducer, .createDownstream, .updateTransactionGeodata:
                true
        }
    }
}
