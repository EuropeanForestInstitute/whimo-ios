//
//  LocalizeKeys.swift
//  Resources
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

public enum LocalizeKeys: String, CaseIterable, Codable {
    case english = "en"
    case french = "fr"
    case spanish = "es"

    public var code: String { self.rawValue }

    public var title: String {
        switch self {
            case .english:
                return "English"
            case .french:
                return "French"
            case .spanish:
                return "Spanish"
        }
    }

    public var locale: Locale {
        switch self {
            case .english:
                return .init(identifier: "en_US")
            case .french:
                return .init(identifier: "fr")
            case .spanish:
                return .init(identifier: "es")
        }
    }

    public static func getLocalize(title: String) -> Self {
        switch title {
            case Self.english.title:
                return Self.english
            case Self.french.title:
                return Self.french
            case Self.spanish.title:
                return Self.spanish
            default:
                preconditionFailure("Unimplemented localization.")
        }
    }
}
