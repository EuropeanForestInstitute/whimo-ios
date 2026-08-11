//
//  NetworkingSession+Error.swift
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

// MARK: - RequestError
extension NetworkingSession {
    public enum RequestError: LocalizedError {
        /// `URLSessionTask` completed with unknown response.
        case unknown
        case some(Swift.Error)
        case clientError(message: String, code: HTTPURLResponse.HTTPStatusCode)
        case serverError(message: String, code: HTTPURLResponse.HTTPStatusCode)
        case decodingError(Swift.Error)
        case connectionLost
        /// `URLSessionTask` completed with error. Indicated low level connection issues.
        /// Thats means that request doesn't reach server and returns with connection error.
        case requestFailed(message: String)
        /// `Request` was explicitly cancelled manually.
        case requestExplicitlyCancelled
        case redirected

        public var errorDescription: String? {
            switch self {
                case .unknown:
                    return "Unknown error."
                case let .some(error):
                    return error.localizedDescription
                case let .clientError(message, code):
                    return "CLIENT ERROR. Code: \(code.rawValue). \(message)"
                case let .serverError(message, code):
                    return "SERVER ERROR. Code: \(code.rawValue). \(message)"
                case let .decodingError(error):
                    return "Decoding error. \(error)"
                case .connectionLost:
                    return "Internet connection is unreachable."
                case .requestFailed(let message):
                    return message
                case .requestExplicitlyCancelled:
                    return "Request explicitly cancelled."
                case .redirected:
                    return "Redirected."
            }
        }
    }
}
