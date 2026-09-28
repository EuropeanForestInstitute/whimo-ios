//
//  ServerErrorCodeTests.swift
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
@testable import RestClient

final class ServerErrorCodeTests: XCTestCase {
    func testKnownServerErrorCodeDecodesAndReachesRestError() throws {
        let rawError = try JSONDecoder().decode(
            RawError.self,
            from: Data(
                """
                {
                  "message": "Contact identifier already exists.",
                  "code": "registration.gadget_already_exists"
                }
                """.utf8
            )
        )

        XCTAssertEqual(rawError.code, .registrationGadgetAlreadyExists)

        let requestError = NetworkingSession.RequestError.clientError(
            message: rawError.message,
            statusCode: .conflict,
            serverErrorCode: rawError.code
        )
        let restError = RestClient.RestError(from: requestError)

        XCTAssertEqual(restError.serverErrorCode, .registrationGadgetAlreadyExists)
        XCTAssertEqual(restError.localizedDescription, "Contact identifier already exists.")
    }

    func testMissingServerErrorCodeRemainsSupported() throws {
        let rawError = try JSONDecoder().decode(
            RawError.self,
            from: Data(#"{"message":"Bad request."}"#.utf8)
        )

        XCTAssertNil(rawError.code)
    }

    func testUnknownServerErrorCodeRemainsAvailable() throws {
        let rawError = try JSONDecoder().decode(
            RawError.self,
            from: Data(
                #"{"message":"Future failure.","code":"registration.future_failure"}"#.utf8
            )
        )

        XCTAssertEqual(rawError.code?.rawValue, "registration.future_failure")
    }
}
