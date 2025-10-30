//
//  AppPhoneNumberTextFieldViewModel.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 27.10.2025.
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
import UIKit
import Contacts
import Utility

/// View model responsible for managing contacts permission and picker for phone number text field
public final class AppPhoneNumberTextFieldViewModel: ObservableObject {
    // MARK: - Public Properties

    /// Controls the presentation of contact picker sheet
    @Published public var isShowingContactPicker = false

    /// Alert manager instance for showing permission alerts
    public let alertManager: AlertManager

    // MARK: - Private Properties
    private let permissionsProvider: ContactsPermissionsProvider?

    // MARK: - Init

    /// Initializes view model with required dependencies
    /// - Parameter permissionsProvider: Provider for contacts permissions
    public init(permissionsProvider: ContactsPermissionsProvider?) {
        self.permissionsProvider = permissionsProvider
        self.alertManager = AlertManager()
    }

    // MARK: - Public Methods

    /// Checks contacts access permission and shows picker if authorized
    /// Uses async/await approach for proper permission handling
    public func checkContactsAccessAndShowPicker() {
        Task { [weak self] in
            guard
                let self,
                let permissionsProvider
            else {
                log.debug("Cannot request contacts, permissions provider not provided")
                return
            }

            let status = await permissionsProvider.requestContacts()

            log.debug("Contacts permission status: \(status.description)")

            await MainActor.run {
                switch status {
                    case .authorized, .limited:
                        log.debug("Contacts permission granted, showing picker")
                        self.isShowingContactPicker = true
                    case .notDetermined:
                        log.debug("Contacts permission not determined, showing alert")
                        self.showContactsPermissionAlert()
                    case .denied, .restricted:
                        log.debug("Contacts permission denied or restricted")
                        self.showContactsPermissionAlert()
                    @unknown default:
                        log.error("Unknown contacts authorization status")
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension AppPhoneNumberTextFieldViewModel {
    /// Shows alert for contacts permission request
    /// - Parameter isFirstTime: Whether this is first time requesting permission
    func showContactsPermissionAlert() {
        alertManager.show(feature: AlertManager.AlertModel.Features.ContactsPermissionDenied.self) { [weak self] key in
            guard let self else { return nil }

            switch key {
                case .cancel:
                    log.debug("User cancelled contacts permission request")
                    return nil
                case .openSettings:
                    log.debug("User requested to open settings")
                    return self.openAppSettings
            }
        }
    }

    /// Opens app settings for user to manually grant permissions
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            log.error("Cannot open app settings")
            return
        }

        UIApplication.shared.open(settingsUrl) { success in
            log.debug("App settings opened: \(success)")
        }
    }
}
