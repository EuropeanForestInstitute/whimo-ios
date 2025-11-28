//
//  PasswordValidator.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 09.06.2025.
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
import Resources

// MARK: - PasswordValidator
struct PasswordValidator {
    private enum Constants {
        static let defaultMinPasswordLenght: Int = 8
    }

    // MARK: - Static Properties
    static let shared: Self = .init()

    // MARK: - Init
    private init() { }

    // MARK: - Internal Methods
    @discardableResult
    func isValid(_ password: String) -> Error? {
        if password.isEmpty {
            return .empty
        }

        let minLength = Constants.defaultMinPasswordLenght
        if password.count < minLength {
            return .tooShort(minLength: minLength)
        }

        if !password.contains(where: { $0.isUppercase }) {
            return .mustContainUppercaseLetter
        }

        return nil
    }

    @discardableResult
    func isValid(_ password: String, repeatPassword: String) -> Error? {
        if password != repeatPassword {
            return .passwordsDoesntMatch
        }

        return nil
    }
}

// MARK: - Error
extension PasswordValidator {
    enum Error: LocalizedError, Equatable {
        private typealias Localization = AppLocale.General.PasswordValidator.Error

        case empty
        case tooShort(minLength: Int)
        case mustContainUppercaseLetter
        case passwordsDoesntMatch

        var errorDescription: String? {
            switch self {
                case .empty:
                    Localization.empty
                case .tooShort(let minLength):
                    Localization.tooShort("\(minLength)")
                case .mustContainUppercaseLetter:
                    Localization.mustContainUppercaseLetter
                case .passwordsDoesntMatch:
                    Localization.passwordsDoesntMatch
            }
        }
    }
}
