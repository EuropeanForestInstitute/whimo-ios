//
//  ContactsPermissionsProvider.swift
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
import Contacts

/// Protocol for providing contacts permission functionality to CommonUI components
///
/// This protocol enables decoupling CommonUI package from app-specific permission services,
/// allowing the app layer to inject its own permission handling implementation.
///
/// ## Usage Example
///
/// ### Implementation in App Layer:
/// ```swift
/// final class PermissionsService: ContactsPermissionsProvider {
///     func requestContacts() async -> CNAuthorizationStatus {
///         let status = CNContactStore.authorizationStatus(for: .contacts)
///
///         switch status {
///             case .notDetermined:
///                 // Request permission from user
///                 return try await CNContactStore().requestAccess(for: .contacts)
///                     ? .authorized
///                     : .denied
///             case .authorized, .limited, .denied, .restricted:
///                 return status
///             @unknown default:
///                 return .denied
///         }
///     }
/// }
/// ```
///
/// ### Usage with AppPhoneNumberTextField:
/// ```swift
/// struct AddRecipientView: View {
///     @Inject(\.permissionsService) private var permissionsService
///     @State private var phoneNumber: String = ""
///
///     var body: some View {
///         AppPhoneNumberTextField(
///             description: "Recipient Phone*",
///             text: $phoneNumber,
///             trailingItem: .phonebook(permissionsProvider: permissionsService)
///         )
///     }
/// }
/// ```
///
/// ### Mock Implementation for Previews:
/// ```swift
/// final class ContactsPermissionsProviderMock: ContactsPermissionsProvider {
///     func requestContacts() async -> CNAuthorizationStatus {
///         .authorized // Always return authorized for preview
///     }
/// }
/// ```
public protocol ContactsPermissionsProvider {
    /// Requests contacts permission from the system
    ///
    /// This method should handle the full permission flow:
    /// - Check current authorization status
    /// - Request permission if not determined
    /// - Return the final authorization status
    ///
    /// - Returns: The authorization status after request (.authorized, .denied, .limited, .restricted, or .notDetermined)
    func requestContacts() async -> CNAuthorizationStatus
}
