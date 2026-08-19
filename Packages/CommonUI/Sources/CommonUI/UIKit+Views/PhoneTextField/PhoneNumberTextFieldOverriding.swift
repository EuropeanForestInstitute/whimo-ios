//
//  PhoneNumberTextFieldOverriding.swift
//  Tollroad
//
//  Created by developer on 20.02.2024.
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
import PhoneNumberKit
import Resources

// MARK: - PhoneNumberTextFieldOverridingDelegate
protocol PhoneNumberTextFieldOverridingDelegate: AnyObject { }

private typealias CurrentView = PhoneNumberTextFieldOverriding
private typealias Localization = AppLocale.General.Keyboard

// MARK: - PhoneNumberTextFieldOverriding
public class PhoneNumberTextFieldOverriding: PhoneNumberTextField {
    typealias Delegate = PhoneNumberTextFieldOverridingDelegate

    // MARK: - Public Properties
    public override var defaultRegion: String {
        get { _defaultRegion }
        set { } // exists for backward compatibility
    }
    public var placeholderColor: UIColor {
        didSet {
            countryCodePlaceholderColor = placeholderColor
            numberPlaceholderColor = placeholderColor
        }
    }
    public var enableToolbar: Bool {
        didSet {
            guard enableToolbar != oldValue || (enableToolbar && inputAccessoryView == nil) else { return }

            if enableToolbar {
                setupToolbar()
            } else {
                self.inputAccessoryView = nil
            }
        }
    }

    weak var textFieldOverridingDelegate: Delegate?

    // MARK: - Private Properties
    private let _defaultRegion: String

    // MARK: - Public Init
    public init(
        defaultRegion: String,
        countryCodePlaceholderColor: UIColor = AppColors.Gray.gray40.color,
        numberPlaceholderColor: UIColor = AppColors.Gray.gray40.color,
        placeholderColor: UIColor = AppColors.Gray.gray40.color,
        font: UIFont? = AppFonts.FiraSans.regular.font(size: 14),
        enableToolbar: Bool = true
    ) {
        // Keep the picker out of the host navigation controller because it manages
        // the navigation bar visibility while it is presented.
        CountryCodePicker.forceModalPresentation = true
        self._defaultRegion = defaultRegion
        self.placeholderColor = placeholderColor
        self.enableToolbar = enableToolbar
        super.init(frame: .zero)

        self.countryCodePlaceholderColor = countryCodePlaceholderColor
        self.numberPlaceholderColor = numberPlaceholderColor
        self.font = font
    }

    required init(coder aDecoder: NSCoder) { preconditionFailure() }
}

// MARK: - Private Methods
private extension PhoneNumberTextFieldOverriding {
    // MARK: - Toolbar
    func setupToolbar() {
        let toolbar: UIToolbar = .init(frame: .init(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 50
        ))
        toolbar.barStyle = .default

        let spacer: UIBarButtonItem = .flexibleSpace()
        let fixedSpacer: UIBarButtonItem = .fixedSpace(8)
        let doneButton: UIBarButtonItem = .init(
            title: Localization.Toolbar.done,
            style: .plain,
            target: self,
            action: #selector(self.didTapDoneAction)
        )
        let doneButtonAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: AppColors.Gray.gray90.color,
            .font: AppFonts.FiraSans.medium.font(size: 16)
        ]
        doneButton.setTitleTextAttributes(doneButtonAttributes, for: .normal)

        let items = [spacer, doneButton, fixedSpacer]
        toolbar.items = items
        toolbar.sizeToFit()

        self.inputAccessoryView = toolbar
    }

    @objc func didTapDoneAction() {
        self.resignFirstResponder()
    }
}
