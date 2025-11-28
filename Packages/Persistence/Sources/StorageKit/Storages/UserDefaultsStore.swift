//
//  UserDefaultsStore.swift
//  Storage
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
import Utility

// MARK: - UserDefaultsStore
public final class UserDefaultsStore: StoreProtocol {
    public typealias Keys = StoreKeys

    private let userDefaults: UserDefaults
    private let persistentDomainName: String

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.persistentDomainName = Bundle.main.bundleIdentifier ?? ""
    }

    // ----------------------------------------------------------------------------
    // Using UserDefaults(suiteName:) for App Group storage may trigger console warnings:
    //
    //   Couldn't read values in CFPrefsPlistSource<...>: Using kCFPreferencesAnyUser with a container
    //   is only allowed for System Containers, detaching from cfprefsd
    //
    // These messages originate from the CFPreferences subsystem and, per Apple engineers,
    // are harmless log noise when working with suite-based defaults. You can continue
    // to rely on UserDefaults(suiteName:) without further action—these warnings can be
    // safely ignored.
    //
    // References:
    // • https://developer.apple.com/forums/thread/765207
    // • https://developer.apple.com/forums/thread/115461
    // ----------------------------------------------------------------------------
    public init(suiteName: String) {
        guard
            let userDefaults: UserDefaults = .init(suiteName: suiteName)
        else {
            log.error("Error: missed suiteName key for UserDefaults initialization")
            preconditionFailure()
        }

        self.userDefaults = userDefaults
        self.persistentDomainName = suiteName
    }

    public func get<T>(_ key: Keys) -> T? where T: Decodable {
        do {
            guard let data = userDefaults.object(forKey: key.rawValue) as? Data else { return nil }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            log.error("error: \(error.localizedDescription)")
            return nil
        }
    }

    public func get<T>(_ key: Keys) -> [T] where T: Decodable {
        do {
            guard let data = userDefaults.object(forKey: key.rawValue) as? Data else { return [] }

            return try JSONDecoder().decode([T].self, from: data)
        } catch let error {
            log.error("error: \(error.localizedDescription)")
            return []
        }
    }

    public func set<T>(_ value: T?, key: Keys) where T: Encodable {
        guard let value = value else {
            userDefaults.set(nil, forKey: key.rawValue)
            return
        }

        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key.rawValue)
        } catch let error {
            log.error("error: \(error.localizedDescription)")
        }
    }

    public func remove(key: Keys) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    public func clear() {
        userDefaults.removePersistentDomain(forName: persistentDomainName)
        userDefaults.synchronize()
    }
}
