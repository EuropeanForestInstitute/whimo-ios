//
// https://gist.github.com/serhii-londar/40df5736130a2b906b173e8338f28d4a
//
//  EmailValidatorTests.swift
//  Whimo
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
//  Created by Vyacheslav Razumeenko on 24.07.2025.
//

import XCTest
@testable import Whimo

final class EmailValidatorTests: XCTestCase {
    private var validator: EmailValidator!

    override func setUpWithError() throws {
        validator = .shared
    }

    override func tearDownWithError() throws {
        validator = nil
    }

    func testValidEmails() {
        let validEmails = [
            "user@example.com",
            "user.name+tag+sorting@example.co.uk",
            "user_name@example.co",
            "user-name@sub.domain.com",
            "user123@domain123.io",
            "U@D.COM"
        ]
        let resultEmails: [String] = validEmails
            .filter {
                let error = validator.isValid($0)
                return error == nil
            }
            .compactMap { $0 }
        XCTAssertEqual(resultEmails, validEmails)
    }

    func testInvalidEmails() {
        let invalidEmails = [
            "plainaddress",                   // no @ symbol
            "@no-local-part.com",             // missing local part
            "user.name@.com",                 // domain starts with a dot
            "user.@domain.com",               // dot before @
            "user@domain..com",               // double dot in domain
            "user@-domain.com",               // hyphen at the start of domain
            "user@domain.com.",               // dot at the end
            "user@domain.com (Joe Smith)",    // space and parentheses
            ""                                // empty string
        ]
        let resultEmails = invalidEmails
            .filter {
                let error = validator.isValid($0)
                return error == nil
            }
            .compactMap { $0 }
        XCTAssertEqual(resultEmails, [])
    }
}
