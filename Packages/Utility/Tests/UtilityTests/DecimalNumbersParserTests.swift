//
//  DecimalNumbersParserTests.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 29.05.2025.
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

import XCTest
@testable import Utility

final class DecimalNumbersParserTests: XCTestCase {
    private var formatter: DecimalNumbersParser!
    private var input: String!

    override func setUpWithError() throws {
        formatter = .default
    }

    override func tearDownWithError() throws {
        formatter = nil
        input = nil
    }

    func testIntegerValueFormatting() throws {
        input = "2"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "2")
    }

    func testFloatingValueFormattingShort() {
        input = "2.12"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "2.12")
    }

    func testFloatingValueFormatting() {
        input = "2.12000"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "2.12000")
    }

    func testFloatingValueFormattingEuropeFormat() {
        input = "2,12000"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "2.12000")
    }

    func testStringValueFormatting() {
        input = "dummy text"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "")
    }

    func testEmptyValueFormatting() {
        input = ""
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "")
    }

    func testMixedValueFormatting() {
        input = "3.14hello"
        let formattedInput = formatter.format(value: input)

        XCTAssertEqual(formattedInput, "")
    }
}
