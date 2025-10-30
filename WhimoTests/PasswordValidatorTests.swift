//
//  PasswordValidatorTests.swift
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

import XCTest
@testable import Whimo

final class PasswordValidatorTests: XCTestCase {
    private var validator: PasswordValidator!

    override func setUpWithError() throws {
        validator = .shared
    }

    override func tearDownWithError() throws {
        validator = nil
    }

    // MARK: - Empty Password Tests
    func testEmptyPassword() {
        let error = validator.isValid("")
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .empty)
    }

    // MARK: - Length Validation Tests
    func testPasswordTooShortNegative() {
        let shortPasswords = [
            "1",
            "Ab",
            "Cat",
            "Dog1",
            "Bird2",
            "Tiger3",
            "Monkey7"
        ]

        let validationErrors = shortPasswords.compactMap { password in validator.isValid(password) }
        let tooShortErrors = validationErrors.compactMap { error in
            switch error {
                case .tooShort:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(validationErrors.count, shortPasswords.count, "All passwords should have validation errors")
        XCTAssertEqual(tooShortErrors.count, shortPasswords.count, "All passwords should have tooShort error")
    }

    func testPasswordTooShortPositive() {
        let validLengthPasswords = [
            "Password",                                  // exactly 8 characters
            "MySecret9",                                 // 9 characters
            "SuperSecurePasswordWith42Characters123456"  // long password
        ]

        let validationErrors = validLengthPasswords.compactMap { password in validator.isValid(password) }
        let tooShortErrors = validationErrors.compactMap { error in
            switch error {
                case .tooShort:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(validationErrors.count, .zero, "All passwords should have no validation errors")
        XCTAssertEqual(tooShortErrors.count, .zero, "No passwords should have tooShort error")
    }

    // MARK: - Uppercase Letter Validation Tests
    func testPasswordWithoutUppercaseLetterNegative() {
        let passwordsWithoutUppercase = [
            "password123",  // common weak password
            "sunshine99",   // word + numbers, no uppercase
            "football!@#"   // word + special chars, no uppercase
        ]
        let validationErrors = passwordsWithoutUppercase.compactMap { password in validator.isValid(password) }
        let uppercaseErrors = validationErrors.compactMap { error in
            switch error {
                case .mustContainUppercaseLetter:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(validationErrors.count, passwordsWithoutUppercase.count, "All passwords should have validation errors")
        XCTAssertEqual(uppercaseErrors.count, passwordsWithoutUppercase.count, "All passwords should have mustContainUppercaseLetter error")
    }

    func testPasswordWithUppercaseLetterPositive() {
        let validPasswords = [
            "Password123",   // classic pattern
            "WELCOME123",    // all caps + numbers
            "BlueSky42!",    // nature + number + special
            "Coffee@Home",   // compound word + special
            "Summer2024A"    // season + year + letter
        ]

        let validationErrors = validPasswords.compactMap { password in validator.isValid(password) }
        let uppercaseErrors = validationErrors.compactMap { error in
            switch error {
                case .mustContainUppercaseLetter:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(validationErrors.count, .zero, "All passwords should have no validation errors")
        XCTAssertEqual(uppercaseErrors.count, .zero, "No passwords should have mustContainUppercaseLetter error")
    }

    // MARK: - Password Matching Tests
    func testPasswordMatchingNegative() {
        let nonMatchingCases = [
            ("BlueSky2024", "BlueSkY2024"),
            ("BlueSky2024", ""),
            ("", "BlueSkY2024")
        ]

        let nonMatchingErrors = nonMatchingCases.compactMap { password, repeatPassword in
            validator.isValid(password, repeatPassword: repeatPassword)
        }
        let mismatchErrors = nonMatchingErrors.compactMap { error in
            switch error {
                case .passwordsDoesntMatch:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(nonMatchingErrors.count, nonMatchingCases.count, "All passwords should have validation errors")
        XCTAssertEqual(mismatchErrors.count, nonMatchingCases.count, "All passwords should have passwordsDoesntMatch error")
    }

    func testPasswordMatchingPositive() {
        let matchingCases = [
            ("MyPassword123", "MyPassword123"),
            ("SecretCode99", "SecretCode99"),
            ("", "")
        ]

        let matchingErrors = matchingCases.compactMap { password, repeatPassword in
            validator.isValid(password, repeatPassword: repeatPassword)
        }
        let mismatchErrors = matchingErrors.compactMap { error in
            switch error {
                case .passwordsDoesntMatch:
                    return error
                default:
                    return nil
            }
        }

        XCTAssertEqual(matchingErrors.count, .zero, "All matching passwords should have no validation errors")
        XCTAssertEqual(mismatchErrors.count, .zero, "No Matching passwords should have passwordsDoesntMatch errors")
    }

    // MARK: - Complete Validation Tests
    func testValidPasswordsPositive() {
        let validPasswords = [
            "Welcome2024",      // common pattern - word + year
            "SecurePass!",      // descriptive + special char
            "Coffee@Morning",   // activity + time + special
            "iPhone15User",     // product + user
        ]

        let validationErrors = validPasswords.compactMap { password in validator.isValid(password) }

        XCTAssertEqual(validationErrors.count, 0, "All passwords should have no validation errors")
    }
}
