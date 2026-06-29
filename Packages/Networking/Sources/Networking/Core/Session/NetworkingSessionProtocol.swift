//
//  NetworkingSessionProtocol.swift
//  Networking
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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
import Alamofire

public protocol NetworkingSessionProtocol: AnyObject {
    var sessionManager: Session { get }
    var decoder: JSONDecoder { get }
    var encoder: JSONEncoder { get }

    var authCredential: OAuthAuthenticator.OAuthCredential? { get set }
    var authDelegate: OAuthAuthenticatorDelegate? { get set }
    var interceptorDelegate: InterceptorDelegate? { get set }

    func makeRequest<Model: Decodable>(_ router: AnyNetworkRouter) async throws -> Model
    func makeMultipartRequest<Model: Decodable>(_ router: AnyUploadNetworkRouter) async throws -> Model

    func tryRequest(_ type: AnyNetworkRouter) throws -> DataRequest
    func tryMultipartRequest(_ type: AnyUploadNetworkRouter) throws -> UploadRequest

    func request(_ type: AnyNetworkRouter) -> DataRequest
    func multipartRequest(_ type: AnyUploadNetworkRouter) -> UploadRequest

    func downloadRequest(
        from url: String,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options
    ) -> DownloadRequest
    func downloadRequest(
        _ type: AnyNetworkRouter,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options
    ) -> DownloadRequest
    func downloadRequest(
        _ router: AnyNetworkRouter,
        to destinationFolderURL: URL?
    ) async throws -> URL?

    func downloadStream(
        from url: String,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options
    ) -> DownloadStream
    func downloadStream(
        _ type: AnyNetworkRouter,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options
    ) -> DownloadStream

    func objectFromData<T: Decodable>(_ data: Data) throws -> T
}

extension NetworkingSessionProtocol {
    public func downloadStream(
        from url: String,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options
    ) -> DownloadStream {
        downloadStream(
            from: url,
            to: destinationFolderURL,
            options: options
        )
    }

    func downloadRequest(
        from url: String,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options = [.removePreviousFile, .createIntermediateDirectories]
    ) -> DownloadRequest {
        downloadRequest(from: url, to: destinationFolderURL, options: options)
    }
}
