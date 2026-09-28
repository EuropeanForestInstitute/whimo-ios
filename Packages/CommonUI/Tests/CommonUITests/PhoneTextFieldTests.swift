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
import Contacts
import PhoneNumberKit
@testable import CommonUI

@MainActor
final class PhoneTextFieldTests: XCTestCase {
    func testFreeSpaceToRightOfMaskHitsPhoneField() throws {
        for width: CGFloat in [320, 360, 402] {
            for text in ["", "+44 20 7031 3000"] {
                try checkFreeSpaceHit(width: width, text: text, trailingItem: .none)
                try checkFreeSpaceHit(width: width, text: text, trailingItem: .phonebook(permissionsProvider: PhonePermissionsStub()))
            }
        }
    }

    func testFocusRequestDoesNotRestoreFocusAfterDismissalOrBindingUpdate() throws {
        let controller = PhoneTextField.FocusController()
        let host = UIHostingController(rootView: PhoneTextField(text: .constant("")).focusController(controller))
        let window = mount(host)
        defer { window.isHidden = true }
        let field = try XCTUnwrap(findPhoneField(in: host.view))

        controller.focus()
        XCTAssertTrue(field.isFirstResponder)
        field.resignFirstResponder()
        host.rootView = PhoneTextField(text: .constant("+44 20 7031 3000")).focusController(controller)
        settleLayout(host)
        XCTAssertFalse(field.isFirstResponder, "A binding update must not reopen the keyboard")
        controller.focus()
        XCTAssertTrue(field.isFirstResponder, "A later tap must be able to reopen the keyboard")
    }

    func testFocusRequestIgnoresDisabledNativeField() throws {
        let controller = PhoneTextField.FocusController()
        let host = UIHostingController(rootView: PhoneTextField(text: .constant("")).focusController(controller))
        let window = mount(host)
        defer { window.isHidden = true }
        let field = try XCTUnwrap(findPhoneField(in: host.view))

        field.isEnabled = false
        controller.focus()
        XCTAssertFalse(field.isFirstResponder)
        field.isEnabled = true
        field.isUserInteractionEnabled = false
        controller.focus()
        XCTAssertFalse(field.isFirstResponder)
    }

    private func checkFreeSpaceHit(width: CGFloat, text: String, trailingItem: AppPhoneNumberTextField.TrailingItem) throws {
        let host = UIHostingController(rootView: AppPhoneNumberTextField(
            text: .constant(text),
            description: "Phone",
            trailingItem: trailingItem
        ).frame(width: width))
        let window = mount(host)
        defer { window.isHidden = true }
        let field = try XCTUnwrap(findPhoneField(in: host.view))
        let frame = field.convert(field.bounds, to: host.view)
        let trailingWidth: CGFloat = if case .phonebook = trailingItem { 58 } else { 0 }
        let rightEdge = host.view.bounds.midX + width / 2 - trailingWidth
        for verticalOffset: CGFloat in [-20, 0, 20] {
            let point = CGPoint(x: rightEdge - 8, y: frame.midY + verticalOffset)
            let hit = host.view.hitTest(point, with: nil)
            XCTAssertTrue(hit === field || hit?.isDescendant(of: field) == true,
                          "Free-space tap misses phone field: width=\(width), frame=\(frame), point=\(point)")
        }
        let flagPoint = field.flagButton.convert(CGPoint(x: field.flagButton.bounds.midX, y: field.flagButton.bounds.midY), to: host.view)
        let flagHit = host.view.hitTest(flagPoint, with: nil)
        XCTAssertTrue(flagHit === field.flagButton || flagHit?.isDescendant(of: field.flagButton) == true)
    }

    private func mount<Content: View>(_ host: UIHostingController<Content>) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 430, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        settleLayout(host)
        return window
    }

    private func settleLayout<Content: View>(_ host: UIHostingController<Content>) {
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        host.view.layoutIfNeeded()
    }

    private func findPhoneField(in view: UIView) -> PhoneNumberTextFieldOverriding? {
        if let field = view as? PhoneNumberTextFieldOverriding { return field }
        return view.subviews.lazy.compactMap { self.findPhoneField(in: $0) }.first
    }

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

private final class PhonePermissionsStub: ContactsPermissionsProvider {
    func requestContacts() async -> CNAuthorizationStatus { .denied }
}
