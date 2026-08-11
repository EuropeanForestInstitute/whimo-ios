//
//  DecimalFormatter.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.06.2025.
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

final class DecimalFormatter: NumberFormatter, @unchecked Sendable {
    private enum Constants {
        static let defaultGroupingSeparator = " "
        static let defaultDecimalSeparator = "."
        static let defaultMinimumFractionDigits = 0
    }

    // MARK: - Static Properties
    static let `default`: DecimalFormatter = .init(
        groupingSeparator: Constants.defaultGroupingSeparator,
        decimalSeparator: Constants.defaultDecimalSeparator,
        minimumFractionDigits: Constants.defaultMinimumFractionDigits
    )
    static let shortFraction: DecimalFormatter = .init(
        groupingSeparator: Constants.defaultGroupingSeparator,
        decimalSeparator: Constants.defaultDecimalSeparator,
        minimumFractionDigits: 1
    )

    // MARK: - Private Properties
    private let defaults: UserDefaults = .standard

    // MARK: - Inits
    convenience init(
        groupingSeparator: String,
        decimalSeparator: String,
        minimumFractionDigits: Int
    ) {
        self.init()

        self.groupingSeparator = groupingSeparator
        self.decimalSeparator = decimalSeparator
        self.minimumFractionDigits = minimumFractionDigits
    }

    override init() {
        super.init()

        let currentLocalize: LocalizeKeys = defaults.value(forKey: UserDefaultsStore.Keys.currentLocalize.rawValue) as? LocalizeKeys ?? .english
        self.locale = currentLocalize.locale
        self.numberStyle = .decimal
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    // MARK: - Public Methods
    func format(value: String) -> String {
        guard
            let floatingPrice: Double = .init(value)
        else { return "" }

        let price = floatingPrice as NSNumber
        let formattedPrice = self.string(from: price) ?? ""

        return formattedPrice
    }
}
