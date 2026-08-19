//
//  PhoneNumberFormatter.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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
import PhoneNumberKit

final class PhoneNumberFormatter: Formatter {
    // MARK: - Static Properties

    /// input: "+380 123 456 789"---> output: "+380123456789"
    static let flat: PhoneNumberFormatter = .init(formatType: .e164)

    // MARK: - Private Properties
    private let phoneNumberUtility: PhoneNumberUtility = .init()
    private let formatType: PhoneNumberFormat

    // MARK: - Inits
    init(formatType: PhoneNumberFormat) {
        self.formatType = formatType
        super.init()
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    func string(from phone: String) throws -> String {
        do {
            let phoneNumber: PhoneNumber = try phoneNumberUtility.parse(phone)
            let formattedPhone = phoneNumberUtility.format(phoneNumber, toType: formatType)

            return formattedPhone
        } catch let error as PhoneNumberError {
            throw Error(from: error)
        }
    }
}
