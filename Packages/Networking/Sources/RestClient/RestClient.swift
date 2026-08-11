//
//  RestClient.swift
//  Networking
//
//  Created by Vyacheslav Razumeenko on 15.07.2025.
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
import Networking
import struct Alamofire.HTTPMethod
import struct Alamofire.HTTPHeaders
import StorageKit

// MARK: - RestClientProtocol
public protocol RestClientProtocol: NetworkingSessionProtocol {
    typealias ClientErrorWorker = RestClientErrorWorker
}

// MARK: - RestClientErrorWorker
public protocol RestClientErrorWorker: AnyObject {
    typealias Endpoint = String
    typealias HTTPMethod = Alamofire.HTTPMethod
    typealias HTTPHeaders = Alamofire.HTTPHeaders

    func unauthorized(_ path: Endpoint, method: HTTPMethod, headers: HTTPHeaders?) async
}

// MARK: - RestClient
public final class RestClient: NetworkingSession, RestClientProtocol {
    // MARK: - Pagination
    public struct Pagination: Decodable {
        public let pageSize: Int
        public let nextPage: Int?
        public let previousPage: Int?
        public let count: Int
        public let totalPages: Int
        public let page: Int

        public static let empty: Self = .init(
            pageSize: .zero,
            nextPage: nil,
            previousPage: nil,
            count: .zero,
            totalPages: .zero,
            page: .zero
        )

        public init(
            pageSize: Int,
            nextPage: Int?,
            previousPage: Int?,
            count: Int,
            totalPages: Int,
            page: Int
        ) {
            self.pageSize = pageSize
            self.nextPage = nextPage
            self.previousPage = previousPage
            self.count = count
            self.totalPages = totalPages
            self.page = page
        }
    }

    public var clientErrorWorker: ClientErrorWorker?

    public override init(baseURL: URL, connectivity: Connectivity, userDefaults: AnyStorage<UserDefaultsStore>) {
        super.init(baseURL: baseURL, connectivity: connectivity, userDefaults: userDefaults)

        self.interceptorDelegate = self
    }

    public override func makeRequest<Model: Decodable>(_ router: AnyNetworkRouter) async throws -> Model {
        do {
            return try await super.makeRequest(router)
        } catch let error as NetworkingSession.RequestError {
            switch error {
                case .clientError(_, let code):
                    if code == .unauthorized {
                        await clientErrorWorker?.unauthorized(
                            router.path,
                            method: router.method,
                            headers: router.headers
                        )
                    }
                default:
                    break
            }

            throw RestClient.RestError(from: error)
        }
    }

    public override func makeMultipartRequest<Model: Decodable>(_ router: AnyUploadNetworkRouter) async throws -> Model {
        do {
            return try await super.makeMultipartRequest(router)
        } catch let error as NetworkingSession.RequestError {
            switch error {
                case .clientError(_, let code):
                    if code == .unauthorized {
                        await clientErrorWorker?.unauthorized(
                            router.path,
                            method: router.method,
                            headers: router.headers
                        )
                    }
                default:
                    break
            }

            throw RestClient.RestError(from: error)
        }
    }

    public override func downloadRequest(_ router: any AnyNetworkRouter, to destinationFolderURL: URL?) async throws -> URL? {
        do {
            return try await super.downloadRequest(router, to: destinationFolderURL)
        } catch let error as NetworkingSession.RequestError {
            switch error {
                case .clientError(_, let code):
                    if code == .unauthorized {
                        await clientErrorWorker?.unauthorized(
                            router.path,
                            method: router.method,
                            headers: router.headers
                        )
                    }
                default:
                    break
            }

            throw RestClient.RestError(from: error)
        }
    }
}

// MARK: - InterceptorDelegate
extension RestClient: InterceptorDelegate {
    public func retry(_ request: Request, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}

// MARK: - ResponseModels
public enum ResponseModels { }
// MARK: - RequestModels
public enum RequestModels { }
