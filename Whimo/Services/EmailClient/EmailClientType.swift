//
//  EmailClientType.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
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

// MARK: - EmailClientType
/// Enum representing third-party email clients supported by the app.
/// RawValue contains URL scheme without "://" suffix for use with canOpenURL and deep linking.
enum EmailClientType: String, CaseIterable {
    case gmail = "googlegmail"
    case defaultBySettings = "mailto"

    var urlScheme: String {
        switch self {
            case .gmail:
                return "\(self.rawValue)://"
            case .defaultBySettings:
                return "\(self.rawValue):"
        }
    }

    // MARK: - Public Methods

    /// Builds deep link URL for the email client with recipient, subject, and body parameters.
    /// - Parameters:
    ///   - recipient: Email recipient address (passed without modifications)
    ///   - subject: Optional email subject (will be URL encoded)
    ///   - body: Optional email body (will be URL encoded)
    /// - Returns: Deep link URL for the email client, or `nil` if URL is invalid
    func buildSendEmailURL(to recipient: String, subject: String?, body: String?) -> URL? {
        var url: URL?

        #if os(iOS) || os(visionOS)
        let encodedSubject = subject?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let encodedBody = body?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        let safeSubject = encodedSubject ?? ""
        let safeBody = encodedBody ?? ""

        switch self {
            case .gmail:
                url = URL(string: "\(urlScheme)co?to=\(recipient)&subject=\(safeSubject)&body=\(safeBody)")
            case .defaultBySettings:
                url = URL(string: "\(urlScheme)\(recipient)?subject=\(safeSubject)&body=\(safeBody)")
        }
        #endif

        return url
    }
}
