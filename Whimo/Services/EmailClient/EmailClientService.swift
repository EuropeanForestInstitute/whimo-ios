//
//  EmailClientService.swift
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

// MARK: - EmailClientService
protocol EmailClientService: AnyObject {
    /// Checks if the specified email client is available on the device.
    /// - Parameter client: The email client to check
    /// - Returns: `true` if the client is available, `false` otherwise
    func checkClientAvailability(_ client: EmailClientType) -> Bool

    /// Opens email client by type
    /// - Parameters:
    ///   - clientType: Email client type to open
    ///   - recipient: Email recipient address
    ///   - subject: Optional email subject
    ///   - body: Optional email body
    /// - Throws: `EmailClientServiceError` if opening fails
    @MainActor
    func openEmailClient(_ clientType: EmailClientType, to recipient: String, subject: String?, body: String?) async throws
}

extension EmailClientService {
    /// Opens email client by type
    /// - Parameters:
    ///   - clientType: Email client type to open
    ///   - recipient: Email recipient address
    ///   - subject: Optional email subject. Nil by default
    ///   - body: Optional email body Nil by default
    /// - Throws: `EmailClientServiceError` if opening fails
    @MainActor
    func openEmailClient(_ clientType: EmailClientType, to recipient: String, subject: String? = nil, body: String? = nil) async throws {
        try await openEmailClient(clientType, to: recipient, subject: subject, body: body)
    }
}
