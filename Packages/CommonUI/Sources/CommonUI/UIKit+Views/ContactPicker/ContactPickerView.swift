//
//  ContactPickerView.swift
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

/// Contact selector control
public struct ContactPicker: UIViewControllerRepresentable {
    public typealias Controller = CNContactPickerViewController

    // MARK: - Public Properties
    public let didPickPhoneNumber: (_ phoneNumber: String) -> Void
    public let didCancel: () -> Void

    // MARK: - Init
    public init(
        didPickPhoneNumber: @escaping (_: String) -> Void,
        didCancel: @escaping () -> Void = {}
    ) {
        self.didPickPhoneNumber = didPickPhoneNumber
        self.didCancel = didCancel
    }

    // MARK: - UIViewControllerRepresentable
    public func makeUIViewController(context: Context) -> Controller {
        let controller: Controller = .init()
        controller.delegate = context.coordinator

        controller.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0"
        )

        return controller
    }

    public func updateUIViewController(_ uiViewController: Controller, context: Context) { }

    public func makeCoordinator() -> Coordinator { .init(parent: self) }
}
