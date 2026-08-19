//
//  NetworkRequestLogFormatterTests.swift
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
import XCTest
@testable import Networking

final class NetworkRequestLogFormatterTests: XCTestCase {
    func testJSONRequestListsParameterNamesWithoutValues() throws {
        var request = try XCTUnwrap(
            URLRequest(url: XCTUnwrap(URL(string: "https://example.test/auth/otp/send/?page=secret-page")))
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer secret-access-token", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "identifier": "participant@example.com",
            "captcha_token": "one-use-token",
            "metadata": ["attempt": 1]
        ])

        let message = NetworkRequestLogFormatter.message(for: request)

        XCTAssertEqual(
            message,
            """
            Request: POST
            Query parameters: page
            Header fields: Authorization, Content-Type
            Body parameters: captcha_token, identifier, metadata.attempt
            """
        )
        XCTAssertFalse(message.contains("participant@example.com"))
        XCTAssertFalse(message.contains("one-use-token"))
        XCTAssertFalse(message.contains("secret-access-token"))
        XCTAssertFalse(message.contains("secret-page"))
    }

    func testFormRequestListsParameterNamesWithoutValues() throws {
        var request = try XCTUnwrap(
            URLRequest(url: XCTUnwrap(URL(string: "https://example.test/search")))
        )
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Data("email=participant%40example.com&enabled=true".utf8)

        let message = NetworkRequestLogFormatter.message(for: request)

        XCTAssertEqual(
            message,
            """
            Request: POST
            Query parameters: <none>
            Header fields: Content-Type
            Body parameters: email, enabled
            """
        )
        XCTAssertFalse(message.contains("participant"))
        XCTAssertFalse(message.contains("true"))
    }
}
