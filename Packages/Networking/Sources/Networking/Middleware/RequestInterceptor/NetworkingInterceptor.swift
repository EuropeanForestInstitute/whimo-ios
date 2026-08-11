//
//  NetworkingInterceptor.swift
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
import StorageKit
import Resources
import Utility

final class BaseRequestInterceptor: RequestInterceptor {
    nonisolated(unsafe) public weak var delegate: InterceptorDelegate?

    private let userDefaults: AnyStorage<UserDefaultsStore>

    init(userDefaults: AnyStorage<UserDefaultsStore>) {
        self.userDefaults = userDefaults
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        guard
            let delegate = delegate
        else {
            completion(.success(urlRequest))
            return
        }

        var urlRequest = urlRequest
        let language: LocalizeKeys = userDefaults.get(.currentLocalize) ?? .english
        urlRequest.headers.add(.acceptLanguage(language.code))

        let headerData = try? JSONSerialization.data(
            withJSONObject: urlRequest.allHTTPHeaderFields ?? [:],
            options: .prettyPrinted
        )
        let header = headerData?.prettyPrintedJSONString ?? .init()

        var message = "Request:"
        message.append("\n🏃🏼‍♂️ \(urlRequest.httpMethod ?? "nil") \(urlRequest.debugDescription)")
        message.append("\n🔸 Header: \(header)")
        message.append("\n🔸 Parameters: \(urlRequest.httpBody?.prettyPrintedJSONString ?? "(RAW) \(urlRequest.httpBody?.toString ?? "")" as NSString)")
        log.debug(message)

        delegate.adapt(urlRequest, completion: completion)
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard
            request.response?.status != .ok
        else {
            completion(.doNotRetry)
            return
        }

        var message = "\n❌ Failure: \(request.description)"
        message.append("\n🔄 Retry count: \(request.retryCount)")
        message.append("\n🔸 Error: \(error). \(error.localizedDescription)")
        log.error(message)

        guard
            let delegate = delegate
        else {
            completion(.doNotRetry)
            return
        }

        delegate.retry(request, dueTo: error, completion: completion)
    }
}
