//
//  TransactionDocumentsServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.07.2025.
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
import Targets
import Utility

final class TransactionDocumentsServiceImpl: TransactionDocumentsService {
    enum Error: LocalizedError {
        case cannotSaveFile

        var errorDescription: String? {
            switch self {
                case .cannotSaveFile:
                    "Cannot save file."
            }
        }
    }

    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let transactionsTarget: any TransactionsTarget
    private let queryMapper: TransactionListQueryMapperProtocol
    private let fileStorage: any FileStorageServiceProtocol

    // MARK: - Init
    init(
        transactionsTarget: any TransactionsTarget,
        fileStorage: any FileStorageServiceProtocol,
        queryMapper: TransactionListQueryMapperProtocol,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.transactionsTarget = transactionsTarget
        self.fileStorage = fileStorage
        self.queryMapper = queryMapper
    }

    // MARK: - TransactionDocumentsService
    func downloadCSV(query: TransactionListQuery) async throws -> URLDocument {
        try await businessDataContext.withCurrentGeneration {
            let request = RequestModels.DownloadCSV(searchData: queryMapper.toDTO(query))
            let response = try await transactionsTarget.downloadCSV(request)
            return .init(response.fileURL.path())
        }
    }

    func downloadCSV(transactionId: String) async throws -> URLDocument {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.DownloadCSV = .init(transactionId: transactionId)
            let response = try await transactionsTarget.downloadCSV(request)
            let url = response.fileURL

            let urlDocument: URLDocument = .init(url.path())
            return urlDocument
        }
    }

    func downloadDocumentsBundle(transactionId: String) async throws -> URLDocument {
        try await businessDataContext.withCurrentGeneration {
            let request: RequestModels.DownloadBundle = .init(transactionId: transactionId)
            let response = try await transactionsTarget.downloadBundle(request)
            let url = response.fileURL

            let urlDocument: URLDocument = .init(url.path())
            return urlDocument
        }
    }
}
