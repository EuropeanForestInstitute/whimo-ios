//
//  KeychainStoreNEW.swift
//  Storage
//
//  Created by Vyacheslav Razumeenko on 23.07.2025.
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
import SimpleKeychain
import Utility

public final class KeychainStore: StoreProtocol {
    public typealias Keys = StoreKeys

    private let keychain: SimpleKeychain

    public init(
        bundleIdentifier: String = Bundle.main.bundleIdentifier!, // swiftlint:disable:this force_unwrapping
        accessGroup: String? = nil
    ) {
        self.keychain = .init(service: bundleIdentifier, accessGroup: accessGroup)
    }

    public func get<T>(_ key: Keys) -> T? where T: Decodable {
        do {
            let data = try keychain.data(forKey: key.rawValue)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            log.error("‼️ Error get value 🔑: \(error.localizedDescription)")
            return nil
        }
    }

    public func get<T>(_ key: Keys) -> [T] where T: Decodable {
        do {
            let data = try keychain.data(forKey: key.rawValue)
            return try JSONDecoder().decode([T].self, from: data)
        } catch let error {
            log.error("🔑 error: \(error.localizedDescription)")
            return []
        }
    }

    public func set<T>(_ value: T?, key: Keys) where T: Encodable {
        guard let value = value else { return }

        do {
            let data = try JSONEncoder().encode(value)

            try keychain.set(data, forKey: key.rawValue)
        } catch let error {
            log.error("‼️ Error set to 🔑: \(error.localizedDescription)")
        }
    }

    public func remove(key: Keys) {
        do {
            try keychain.deleteItem(forKey: key.rawValue)
        } catch let error {
            log.error("‼️ Error remove from 🔑: \(error.localizedDescription)")
        }
    }

    public func clear() {
        do {
            try keychain.deleteAll()
        } catch let error {
            log.error("‼️ Error remove all 🔑: \(error.localizedDescription)")
        }
    }
}
