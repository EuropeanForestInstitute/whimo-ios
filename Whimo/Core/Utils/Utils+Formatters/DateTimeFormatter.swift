//
//  DateTimeFormatter.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 20.05.2025.
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
import enum Resources.LocalizeKeys
import class StorageKit.UserDefaultsStore

// MARK: - DateTimeFormatter
final class DateTimeFormatter: DateFormatter, @unchecked Sendable {
    private enum DateFormat {
        static let defaultFormat = "dd MMMM HH:mm"
        static let fileObjectFormat = "MMM d, yyyy, HH:mm:ss"
        static let transactionFormat = "MMMM d, yyyy HH:mm a"
    }

    // MARK: - Public Properties
    /// format: `dd MMMM HH:mm`
    ///
    /// example: 30 July 10:33
    static let `default`: DateTimeFormatter = .init(dateFormat: DateFormat.defaultFormat)
    static let fileObject: DateTimeFormatter = .init(dateFormat: DateFormat.fileObjectFormat)
    static func transaction(locale: Locale? = nil) -> DateTimeFormatter {
        .init(
            dateFormat: DateFormat.transactionFormat,
            formatOptions: [.withInternetDateTime, .withFractionalSeconds],
            locale: locale
        )
    }
    static let iso8601: DateTimeFormatter = .init(
        dateFormat: "",
        formatOptions: [.withInternetDateTime, .withFractionalSeconds]
    )

    // MARK: - Private Properties
    private let defaults: UserDefaults = .standard
    private let dateFormatterISO8601: ISO8601DateFormatter = .init()

    // MARK: - Init
    convenience init(dateFormat: String, formatOptions: ISO8601DateFormatter.Options = [], locale: Locale? = nil) {
        self.init()
        self.dateFormat = dateFormat
        self.dateFormatterISO8601.formatOptions = formatOptions
        if let locale {
            self.locale = locale
        } else {
            let currentLocalize: LocalizeKeys = defaults.value(forKey: UserDefaultsStore.Keys.currentLocalize.rawValue) as? LocalizeKeys ?? .english
            self.locale = currentLocalize.locale
        }
    }

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    // MARK: - Public Methods
    /// - Parameter textDate: example: "2024-07-24T10:32:02+00:00"
    func format(textDate: String) -> String? {
        guard let date = dateFormatterISO8601.date(from: textDate) else { return "" }

        return self.string(from: date)
    }

    func format(date: Date) -> String {
        dateFormatterISO8601.string(from: date)
    }

    override func date(from string: String) -> Date? {
        dateFormatterISO8601.date(from: string)
    }
}
