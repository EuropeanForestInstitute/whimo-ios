//
//  BundleConfiguration.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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

// MARK: - BundleConfiguration
enum BundleConfiguration {
    // MARK: - Constants
    private enum Constants {
        #if DEBUG
        static let bundleIdentifierSuffix: String = ".dev"
        #elseif STAGE
        static let bundleIdentifierSuffix: String = ".stage"
        #elseif RELEASE
        static let bundleIdentifierSuffix: String = ""
        #endif
    }

    // MARK: - Public Static Properties
    static let bundleIdentifier: String = "com.maddevs.Whimo\(Constants.bundleIdentifierSuffix)"

    static let keychainAccessGroup = "com.keychain.Whimo\(Constants.bundleIdentifierSuffix)"
    static let teamID = "TEAM_ID"
    static var keychainAccessGroupFullName: String { "\(teamID).\(keychainAccessGroup)" }

    static let appGroupUserDefaultsStore = "group.maddevs.Whimo\(Constants.bundleIdentifierSuffix).bundle"
}
