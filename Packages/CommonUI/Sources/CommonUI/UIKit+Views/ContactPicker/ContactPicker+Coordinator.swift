//
//  ContactPicker+Coordinator.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 02.05.2025.
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

import SwiftUI
import ContactsUI
import Utility

// MARK: - Coordinator
public extension ContactPicker {
    final class Coordinator: NSObject, CNContactPickerDelegate {
        // MARK: - Private Properties
        private var parent: ContactPicker

        // MARK: - Init
        public init(parent: ContactPicker) {
            self.parent = parent
        }

        // MARK: - CNContactPickerDelegate
        public func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contactProperty: CNContactProperty
        ) {
            switch parent.pickerType {
                case .phoneNumber:
                    guard let phoneNumber = contactProperty.value as? CNPhoneNumber else {
                        log.error("Failed to extract phone number from contact")
                        return
                    }

                    let formattedNumber = phoneNumber.stringValue
                    log.debug("Selected phone number: \(formattedNumber)")
                    parent.didPickProperty(formattedNumber)
                case .emailAddress:
                    guard let emailAddress = contactProperty.value as? String else {
                        log.error("Failed to extract email address from contact")
                        return
                    }

                    log.debug("Selected email address: \(emailAddress)")
                    parent.didPickProperty(emailAddress)
            }
        }

        public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            log.debug("Contact picker cancelled")
            parent.dismiss()
        }
    }
}
