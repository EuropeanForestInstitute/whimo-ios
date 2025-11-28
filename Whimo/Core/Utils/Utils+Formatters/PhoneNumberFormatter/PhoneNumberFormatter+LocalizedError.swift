//
//  PhoneNumberFormatter+LocalizedPhoneError.swift
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
import Resources

private typealias Localization = AppLocale.General.Formatters.PhoneNumber.Error

// MARK: - Error
extension PhoneNumberFormatter {
    public enum Error: Equatable {
        case generalError
        case invalidCountryCode
        case invalidNumber
        case tooLong
        case tooShort
        case deprecated
        case metadataNotFound
        case ambiguousNumber(phoneNumbers: Set<PhoneNumber>)

        init(from case: PhoneNumberError) {
            switch `case` {
                case .generalError:
                    self = .generalError
                case .invalidCountryCode:
                    self = .invalidCountryCode
                case .invalidNumber:
                    self = .invalidNumber
                case .tooLong:
                    self = .tooLong
                case .tooShort:
                    self = .tooShort
                case .deprecated:
                    self = .deprecated
                case .metadataNotFound:
                    self = .metadataNotFound
                case .ambiguousNumber(let phoneNumbers):
                    self = .ambiguousNumber(phoneNumbers: phoneNumbers)
            }
        }
    }
}

// MARK: - PhoneNumberFormatter.Error+LocalizedError
extension PhoneNumberFormatter.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .generalError: Localization.generalError
            case .invalidCountryCode: Localization.invalidCountryCode
            case .invalidNumber: Localization.invalidNumber
            case .tooLong: Localization.tooLong
            case .tooShort: Localization.tooShort
            case .deprecated: Localization.deprecated
            case .metadataNotFound: Localization.metadataNotFound
            case .ambiguousNumber: Localization.ambiguousNumber
        }
    }
}
