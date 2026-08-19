//
//  DecimalNumbersParser.swift
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

import Foundation

public final class DecimalNumbersParser {
    private enum Constants {
        static let defaultPattern = "^(?!(?:[1-9]\\d*|0|\\d+\\.\\d+|\\d+\\.)$).+$"
    }

    // MARK: - Static Properties
    public static let `default`: DecimalNumbersParser = .init()

    // MARK: - Public Properties

    // MARK: - Private Properties
    private let pattern = Constants.defaultPattern

    // MARK: - Inits
    public init() { }

    public func string(from namePart: String) -> String {
        let result = namePart
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        return result
    }

    public func format(value: String) -> String {
        string(from: value)
    }
}
