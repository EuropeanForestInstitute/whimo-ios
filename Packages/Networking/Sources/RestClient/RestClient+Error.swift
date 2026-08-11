//
//  RestClient+Error.swift
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
import Resources

private typealias Localization = AppLocale.General.Networking.Errors

// MARK: - RestError
extension RestClient {
    public enum RestError: LocalizedError {
        case unknown
        case error(message: String)
        case clientError(message: String, code: HTTPURLResponse.HTTPStatusCode)
        case serverError(message: String, code: HTTPURLResponse.HTTPStatusCode)
        case decodingError
        case connectionLost
        case redirected

        public var errorDescription: String? {
            switch self {
                case .unknown:
                    Localization.unknown
                case .error(let message):
                    message
                case .clientError(let message, _):
                    message
                case .serverError(let message, _):
                    message
                case .decodingError:
                    Localization.decodingError
                case .connectionLost:
                    Localization.connectionLost
                case .redirected:
                    "Redirected."
            }
        }

        // MARK: - Init
        public init(from requestError: NetworkingSession.RequestError) {
            switch requestError {
                case .unknown:
                    self = .unknown
                case .some(let error):
                    self = .error(message: error.localizedDescription)
                case .clientError(let message, let code):
                    self = .clientError(message: "\(message)", code: code)
                case .serverError(let message, let code):
                    self = .serverError(message: "\(message)", code: code)
                case .decodingError:
                    self = .decodingError
                case .connectionLost:
                    self = .connectionLost
                case .requestFailed(let message):
                    self = .error(message: message)
                case .requestExplicitlyCancelled:
                    self = .error(message: requestError.localizedDescription)
                case .redirected:
                    self = .redirected
            }
        }
    }
}
