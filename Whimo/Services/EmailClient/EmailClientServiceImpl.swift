//
//  EmailClientServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
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
import UIKit
import Utility

// MARK: - EmailClientServiceImpl
final class EmailClientServiceImpl: EmailClientService {
    // MARK: - Dependepcies
    private let application: UIApplication

    // MARK: - Init
    init() {
        self.application = .shared
    }

    // MARK: - EmailClientService

    /// Checks if the specified email client is available on the device.
    /// - Parameter client: The email client to check
    /// - Returns: `true` if the client is available, `false` otherwise
    func checkClientAvailability(_ client: EmailClientType) -> Bool {
        guard let url = URL(string: client.urlScheme) else {
            log.error("Invalid URL scheme for client: \(client.rawValue)")
            return false
        }

        let isAvailable = application.canOpenURL(url)
        log.debug("Email client \(client.rawValue) is available: \(isAvailable)")
        return isAvailable
    }

    /// Opens email client by type
    /// - Parameters:
    ///   - clientType: Email client type to open
    ///   - recipient: Email recipient address
    ///   - subject: Optional email subject
    ///   - body: Optional email body
    /// - Throws: `EmailClientServiceError` if opening fails
    @MainActor
    func openEmailClient(_ clientType: EmailClientType, to recipient: String, subject: String?, body: String?) async throws {
        #if targetEnvironment(simulator)
        throw Error.simulatorNotSupported
        #else
        guard
            let url = clientType.buildSendEmailURL(to: recipient, subject: subject, body: body)
        else {
            let error: Error = .invalidUrl
            log.error("Cannot get url for \(clientType). Error: \(error.localizedDescription)")
            throw error
        }

        log.debug("\(clientType) URL: \(String(describing: url.absoluteString))")
        try await openURL(url)
        #endif
    }
}

// MARK: - Private Methods
private extension EmailClientServiceImpl {
    @MainActor
    func openURL(_ url: URL) async throws {
        guard application.canOpenURL(url) else {
            log.error("Cannot open URL: \(url.absoluteString)")
            let error = Error.cannotOpenURL(url: url)
            throw error
        }

        let success = await application.open(url)
        guard success else {
            let error = Error.cannotOpenURL(url: url)
            log.error("Cannot open URL: \(url.absoluteString)")
            throw error
        }
        log.debug("Successfully opened URL: \(url.absoluteString)")
    }
}
