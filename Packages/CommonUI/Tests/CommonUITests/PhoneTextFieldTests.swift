//
//  PhoneTextFieldTests.swift
//  CommonUI
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import SwiftUI
import PhoneNumberKit
@testable import CommonUI

@MainActor
final class PhoneTextFieldTests: XCTestCase {
    func testCountrySelectionClearsBoundPhoneNumberAndUpdatesRegion() {
        var phone = "+44 20 7031 3000"
        let textBinding = Binding<String>(
            get: { phone },
            set: { phone = $0 }
        )
        let coordinator = PhoneTextField.Coordinator(text: textBinding)
        let textField = PhoneNumberTextFieldOverriding(defaultRegion: "GB")
        textField.text = phone
        coordinator.observe(textField)

        guard let country = CountryCodePickerViewController.Country(for: "US", with: textField.utility) else {
            XCTFail("The US country metadata should be available")
            return
        }

        textField.countryCodePickerViewControllerDidPickCountry(country)

        XCTAssertEqual(phone, "")
        XCTAssertEqual(textField.currentRegion, "US")
    }

    func testApplyingBindingTextDoesNotRepublishDuringRepresentableUpdate() {
        var phone = "+44 20 7031 3000"
        var bindingWriteCount = 0
        let textBinding = Binding<String>(
            get: { phone },
            set: {
                phone = $0
                bindingWriteCount += 1
            }
        )
        let coordinator = PhoneTextField.Coordinator(text: textBinding)
        let textField = PhoneNumberTextFieldOverriding(defaultRegion: "GB")
        coordinator.observe(textField)

        coordinator.applyBindingText(phone, to: textField)

        XCTAssertEqual(bindingWriteCount, 0, "A representable update must not publish its own text change")
    }

    func testReenablingToolbarKeepsExistingToolbar() {
        let textField = PhoneNumberTextFieldOverriding(defaultRegion: "US")
        textField.enableToolbar = true

        guard let initialToolbar = textField.inputAccessoryView else {
            XCTFail("Enabling the toolbar should install an input accessory view")
            return
        }

        textField.enableToolbar = true

        guard let currentToolbar = textField.inputAccessoryView else {
            XCTFail("The input accessory view should remain installed")
            return
        }

        XCTAssertTrue(initialToolbar === currentToolbar)
    }

    func testPhoneTextFieldUsesModalCountryPickerPresentation() {
        CountryCodePicker.forceModalPresentation = false

        _ = PhoneNumberTextFieldOverriding(defaultRegion: "US")

        XCTAssertTrue(CountryCodePicker.forceModalPresentation)
    }
}
