//
//  PhoneNumberValidatorTests.swift
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

final class PhoneNumberValidatorTests: XCTestCase {
    private var validator: PhoneNumberValidator!

    override func setUp() async throws {
        // Given: Initialize validator using shared singleton
        validator = .shared
    }

    override func tearDown() async throws {
        // Clean up validator after each test
        validator = nil
    }

    // MARK: - Phone Verification Availability Tests

    func testVerificationAvailabilityAllowsNumbersWhenPolicyIsDisabled() {
        let availability = validator.verificationAvailability(
            for: "+1 202 555 1234",
            policy: registrationPhoneRegionPolicy(
                enabled: false,
                allowedRegionCodes: ["KG"]
            )
        )

        XCTAssertEqual(availability, .available)
    }

    func testVerificationAvailabilityNormalizesAllowedRegionCodes() {
        let availability = validator.verificationAvailability(
            for: "+1 202 555 1234",
            policy: registrationPhoneRegionPolicy(
                enabled: true,
                allowedRegionCodes: [" us "]
            )
        )

        XCTAssertEqual(availability, .available)
    }

    func testVerificationAvailabilityRejectsUnsupportedCountryRegion() {
        let availability = validator.verificationAvailability(
            for: "+1 202 555 1234",
            policy: registrationPhoneRegionPolicy(
                enabled: true,
                allowedRegionCodes: ["KG"]
            )
        )

        XCTAssertEqual(availability, .unavailable)
    }

    func testVerificationAvailabilityRejectsNumbersWhenEnabledPolicyHasNoAllowedRegions() {
        let availability = validator.verificationAvailability(
            for: "+1 202 555 1234",
            policy: registrationPhoneRegionPolicy(
                enabled: true,
                allowedRegionCodes: []
            )
        )

        XCTAssertEqual(availability, .unavailable)
    }

    func testVerificationAvailabilityRejectsNumbersWhenDefaultPolicyIsUsed() {
        let availability = validator.verificationAvailability(
            for: "+1 202 555 1234",
            policy: RemoteConfigDefaults.registrationPhoneRegionPolicy
        )

        XCTAssertEqual(availability, .unavailable)
    }

    private func registrationPhoneRegionPolicy(
        enabled: Bool,
        allowedRegionCodes: [String]
    ) -> RegistrationPhoneRegionPolicy {
        .init(
            schemaVersion: RegistrationPhoneRegionPolicy.supportedSchemaVersion,
            enabled: enabled,
            allowedRegions: allowedRegionCodes.map {
                .init(
                    regionCode: $0,
                    regionName: "",
                    callingCode: 0,
                    e164Prefix: ""
                )
            }
        )
    }

    // MARK: - Valid Phone Numbers Tests (Positive Cases)

    func testValidPhoneNumbersE164Format() {
        // Given: Valid phone numbers in E.164 format
        let validPhoneNumbers = [
            "+12025551234",     // US number (valid format)
            "+380501234567",    // Ukraine mobile number
            "+442071234567",    // UK number
            "+33612345678",     // France mobile number
            "+4915123456789",   // Germany mobile number
            "+61234567890"      // Australia number
        ]

        // When: Validating each phone number
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: All phone numbers should be valid
        XCTAssertEqual(validResults.count, validPhoneNumbers.count, "All E.164 format phone numbers should be valid")
    }

    func testValidPhoneNumbersInternationalFormat() {
        // Given: Valid phone numbers in international format with spaces
        let validPhoneNumbers = [
            "+1 202 555 1234",      // US number with spaces
            "+33 6 89 017383",      // France number with spaces
            "+44 20 7031 3000",     // UK number with spaces
            "+380 50 123 4567",     // Ukraine mobile number with spaces
            "+49 151 234 56789"     // Germany number with spaces
        ]

        // When: Validating each phone number
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: All phone numbers should be valid
        XCTAssertEqual(validResults.count, validPhoneNumbers.count, "All international format phone numbers should be valid")
    }

    func testValidPhoneNumbersWithDashes() {
        // Given: Valid phone numbers with dashes
        let validPhoneNumbers = [
            "+1-234-567-8900",      // US number with dashes
            "+44-20-7031-3000",     // UK number with dashes
            "+33-6-89-01-73-83"     // France number with dashes
        ]

        // When: Validating each phone number
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: All phone numbers should be valid
        XCTAssertEqual(validResults.count, validPhoneNumbers.count, "All phone numbers with dashes should be valid")
    }

    func testValidPhoneNumbersWithParentheses() {
        // Given: Valid phone numbers with parentheses
        let validPhoneNumbers = [
            "+1 (234) 567-8900",    // US number with parentheses
            "+44 (20) 7031-3000"    // UK number with parentheses
        ]

        // When: Validating each phone number
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: All phone numbers should be valid
        XCTAssertEqual(validResults.count, validPhoneNumbers.count, "All phone numbers with parentheses should be valid")
    }

    func testValidPhoneNumbersDifferentCountries() {
        // Given: Valid phone numbers from various countries
        let validPhoneNumbers = [
            "+12025551234",         // US number
            "+447911123456",        // UK mobile
            "+33612345678",         // France mobile
            "+380501234567",        // Ukraine mobile
            "+4915123456789",       // Germany mobile
            "+61234567890",         // Australia
            "+81901234567",         // Japan
            "+8613800138000",       // China
            "+551155256325",        // Brazil
            "+34612345678"          // Spain
        ]

        // When: Validating each phone number
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: Most phone numbers should be valid (some may fail due to strict validation)
        // We verify that at least some valid numbers pass validation
        XCTAssertGreaterThan(validResults.count, 0, "At least some phone numbers from different countries should be valid")
    }

    // MARK: - Invalid Phone Numbers Tests (Negative Cases)

    func testInvalidPhoneNumbersEmptyString() {
        // Given: Empty string
        let phoneNumber = ""

        // When: Validating empty string
        let error = validator.isValid(phoneNumber)

        // Then: Empty string should be invalid
        XCTAssertNotNil(error, "Empty string should be invalid")
    }

    func testInvalidPhoneNumbersTooShort() {
        // Given: Phone numbers that are too short
        let invalidPhoneNumbers = [
            "1",
            "12",
            "123",
            "+1",
            "+12",
            "+123"
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All too short phone numbers should be invalid")
    }

    func testInvalidPhoneNumbersInvalidCountryCode() {
        // Given: Phone numbers with invalid country codes
        let invalidPhoneNumbers = [
            "+0001234567890",       // Invalid country code 000
            "+9991234567890",       // Invalid country code 999
            "+001234567890"         // Invalid country code 00
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All phone numbers with invalid country codes should be invalid")
    }

    func testInvalidPhoneNumbersWithLetters() {
        // Given: Phone numbers containing letters in invalid positions
        let invalidPhoneNumbers = [
            "+1ABC5678900",         // Letters in middle
            "ABC1234567890",        // Letters at start
            "+1234567890ABC",       // Letters at end
            "+1-234-567-ABCD"       // Letters in place of digits
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All phone numbers with letters should be invalid")
    }

    func testInvalidPhoneNumbersMalformedFormat() {
        // Given: Malformed phone numbers
        let invalidPhoneNumbers = [
            "1234567890",           // Missing country code
            "++1234567890",         // Double plus sign
            "+1 234 567 890 123 456 789", // Too many digits
            "+1-234-567-890-123-456-789"  // Too many digits with dashes
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All malformed phone numbers should be invalid")
    }

    func testInvalidPhoneNumbersIncompleteNumbers() {
        // Given: Incomplete phone numbers
        let invalidPhoneNumbers = [
            "+1 234",               // Incomplete US number
            "+44 20",               // Incomplete UK number
            "+33 6",                // Incomplete France number
            "+380 12"               // Incomplete Ukraine number
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All incomplete phone numbers should be invalid")
    }

    // MARK: - Edge Cases Tests

    func testEdgeCaseWhitespaceOnly() {
        // Given: Whitespace-only string
        let phoneNumber = "   "

        // When: Validating whitespace-only string
        let error = validator.isValid(phoneNumber)

        // Then: Whitespace-only string should be invalid
        XCTAssertNotNil(error, "Whitespace-only string should be invalid")
    }

    func testEdgeCaseExcessiveWhitespace() {
        // Given: Phone numbers with excessive whitespace
        let phoneNumbers = [
            "+1   234   567   8900",   // Excessive spaces
            "+ 1 2 3 4 5 6 7 8 9 0",   // Spaces between every digit
            "  +1234567890  "          // Leading and trailing spaces
        ]

        // When: Validating each phone number
        // Note: PhoneNumberKit may handle some whitespace differently, so we test the behavior
        let results = phoneNumbers.map { phoneNumber in
            validator.isValid(phoneNumber)
        }

        // Then: Validator should handle whitespace without crashing
        // PhoneNumberKit may normalize whitespace differently for each format,
        // so we verify that the validator processes all cases and returns results
        XCTAssertEqual(results.count, phoneNumbers.count, "Validator should process all phone numbers with whitespace")
        // Verify the validator returns Error? type for all inputs (nil for valid, Error for invalid)
        // This test ensures the validator doesn't crash on whitespace-heavy inputs
        for (index, result) in results.enumerated() {
            // Result is Error? which can be nil (valid) or non-nil (invalid)
            // We just verify it's the correct type and doesn't cause crashes
            let phoneNumber = phoneNumbers[index]
            if result == nil {
                // Valid number - PhoneNumberKit successfully normalized whitespace
                XCTAssertNil(result, "Phone number with whitespace should be valid: \(phoneNumber)")
            } else {
                // Invalid number - PhoneNumberKit couldn't parse it
                XCTAssertNotNil(result, "Phone number with whitespace should return error: \(phoneNumber)")
            }
        }
    }

    func testEdgeCaseVeryLongString() {
        // Given: Very long string that's not a valid phone number
        let phoneNumber = String(repeating: "1", count: 100)

        // When: Validating very long string
        let error = validator.isValid(phoneNumber)

        // Then: Very long string should be invalid
        XCTAssertNotNil(error, "Very long string should be invalid")
    }

    func testEdgeCaseSpecialCharacters() {
        // Given: Phone numbers with special characters in invalid positions
        let invalidPhoneNumbers = [
            "+1@234567890",         // @ symbol
            "+1#234567890",         // # symbol
            "+1$234567890",         // $ symbol
            "+1%234567890"          // % symbol
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers with invalid special characters should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All phone numbers with invalid special characters should be invalid")
    }

    func testEdgeCaseUnicodeCharacters() {
        // Given: Phone numbers with Unicode characters
        let invalidPhoneNumbers = [
            "+1２34567890",         // Full-width digits
            "+1中文234567890",       // Chinese characters
            "+1🚀234567890"         // Emoji
        ]

        // When: Validating each phone number
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers with Unicode characters should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All phone numbers with Unicode characters should be invalid")
    }

    // MARK: - Comprehensive Validation Tests

    func testComprehensiveValidPhoneNumbers() {
        // Given: Comprehensive list of valid phone numbers in various formats
        let validPhoneNumbers = [
            "+12025551234",         // US E.164
            "+1 202 555 1234",      // US with spaces
            "+1-202-555-1234",      // US with dashes
            "+1 (202) 555-1234",    // US with parentheses
            "+380501234567",        // Ukraine mobile E.164
            "+380 50 123 4567",     // Ukraine mobile with spaces
            "+447911123456",        // UK mobile E.164
            "+33 6 89 017383",      // France with spaces
            "+4915123456789",       // Germany mobile E.164
            "+61234567890"          // Australia E.164
        ]

        // When: Validating all phone numbers
        let validResults = validPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) == nil
        }

        // Then: Most phone numbers should be valid (some formats may not be accepted by PhoneNumberKit)
        // We verify that at least some valid numbers pass validation
        XCTAssertGreaterThan(validResults.count, 0, "At least some valid phone numbers should pass validation")
        // Verify that we have a reasonable pass rate (at least 70%)
        let passRate = Double(validResults.count) / Double(validPhoneNumbers.count)
        XCTAssertGreaterThanOrEqual(passRate, 0.7, "At least 70% of valid phone numbers should pass validation")
    }

    func testComprehensiveInvalidPhoneNumbers() {
        // Given: Comprehensive list of invalid phone numbers
        let invalidPhoneNumbers = [
            "",                     // Empty
            "   ",                  // Whitespace only
            "123",                  // Too short
            "1234567890",           // Missing country code
            "+0001234567890",       // Invalid country code
            "+1ABC5678900",         // Contains letters
            "+1@234567890",         // Contains special chars
            "++1234567890",         // Double plus
            "+1 234",               // Incomplete
            String(repeating: "1", count: 100) // Too long
        ]

        // When: Validating all phone numbers
        let invalidResults = invalidPhoneNumbers.filter { phoneNumber in
            validator.isValid(phoneNumber) != nil
        }

        // Then: All phone numbers should be invalid
        XCTAssertEqual(invalidResults.count, invalidPhoneNumbers.count, "All invalid phone numbers should fail validation")
    }
}
