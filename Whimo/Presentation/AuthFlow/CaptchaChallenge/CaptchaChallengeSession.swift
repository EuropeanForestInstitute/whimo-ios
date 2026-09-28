//
//  CaptchaChallengeSession.swift
//  Whimo
//
//  Copyright (c) 2026 EFI https://efi.int/
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

// MARK: - CaptchaChallengeSession
final class CaptchaChallengeSession {
    // MARK: - Nested Types
    enum Effect: Equatable {
        case noChange
        case finish(Outcome)
    }

    enum Outcome: Equatable {
        case token(String)
        case cancelled
        case failure
    }

    // MARK: - Private Properties
    private let formOrigin: Origin?
    private var isFinished = false

    // MARK: - Public Properties
    let formURL: URL

    // MARK: - Init
    init(formURL: URL) {
        self.formURL = formURL
        self.formOrigin = Origin(url: formURL)
    }

    // MARK: - Public Methods
    func handleBridgeMessage(body: String, sourceURL: URL) -> Effect {
        guard !isFinished else { return .noChange }
        guard formOrigin == Origin(url: sourceURL) else { return finish(.failure) }
        guard let message = try? JSONDecoder().decode(
            BridgeMessage.self,
            from: Data(body.utf8)
        ) else {
            return finish(.failure)
        }

        switch message.status {
            case .success:
                guard
                    let token = message.token,
                    !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return finish(.failure)
                }

                return finish(.token(token))
            case .error:
                guard
                    let code = message.code,
                    BridgeMessage.RecoverableError(rawValue: code) != nil
                else {
                    return finish(.failure)
                }

                return .noChange
        }
    }

    func handleNavigationFailure() -> Effect {
        guard !isFinished else { return .noChange }
        return finish(.failure)
    }

    func cancel() -> Effect {
        guard !isFinished else { return .noChange }
        return finish(.cancelled)
    }

    func allowsTopLevelNavigation(to url: URL) -> Bool {
        formOrigin == Origin(url: url)
    }
}

// MARK: - Private Methods
private extension CaptchaChallengeSession {
    func finish(_ outcome: Outcome) -> Effect {
        isFinished = true
        return .finish(outcome)
    }
}

// MARK: - BridgeMessage
private extension CaptchaChallengeSession {
    struct BridgeMessage: Decodable {
        enum Status: String, Decodable {
            case success
            case error
        }

        enum RecoverableError: String {
            case scriptError = "script_error"
            case renderError = "render_error"
            case expired
        }

        let status: Status
        let token: String?
        let code: String?
    }
}

// MARK: - Origin
private extension CaptchaChallengeSession {
    struct Origin: Equatable {
        let scheme: String
        let host: String
        let port: Int?

        init?(url: URL) {
            guard
                let scheme = url.scheme?.lowercased(),
                let host = url.host?.lowercased()
            else { return nil }

            self.scheme = scheme
            self.host = host
            self.port = Self.normalizedPort(url.port, scheme: scheme)
        }

        private static func normalizedPort(_ port: Int?, scheme: String) -> Int? {
            switch (scheme, port) {
                case ("https", 443), ("http", 80):
                    return nil
                default:
                    return port
            }
        }
    }
}
