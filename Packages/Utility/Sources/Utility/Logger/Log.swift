//
//  Log.swift
//  Utility
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
import OSLog

// MARK: - log
public var log: Log { Log.default } // swiftlint:disable:this identifier_name

// MARK: - Logger Wrapper
public struct Log: LogProtocol {
    fileprivate static let `default`: Log = .init(category: "default") // swiftlint:disable:this strict_fileprivate

    // MARK: - Private Properties
    private let logger: Logger
    private let dateFormatter: DateFormatter = build {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    // MARK: - Init
    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "",
        category: String
    ) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - LoggerProtocol
    public func log(
        level: OSLogType,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        _ message: String = "",
        _ separator: String = ""
    ) {
        let file: String = "\(file)"
        let shotFileName = (file as NSString).lastPathComponent
        let date: Date = .now
        let stringDate = dateFormatter.string(from: date)

        logger.log(level: level, "\(stringDate) \(shotFileName).\(function):\(line) | \(separator) | \(message)")
    }

    public func debug(
        _ message: String = "",
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line
    ) {
        log(level: .debug, file: file, function: function, line: line, message, "DEBUG")
    }

    public func info(
        _ message: String,
        file: StaticString,
        function: StaticString,
        line: Int
    ) {
        log(level: .info, file: file, function: function, line: line, message, "INFO")
    }

    public func fault(
        _ message: String,
        file: StaticString,
        function: StaticString,
        line: Int
    ) {
        log(level: .fault, file: file, function: function, line: line, message, "FAULT")
    }

    public func error(
        _ message: String = "",
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line
    ) {
        log(level: .error, file: file, function: function, line: line, message, "ERROR")
    }
}
