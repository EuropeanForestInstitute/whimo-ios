//
//  BusinessModeRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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
import Combine
import StorageKit

final class BusinessModeRepositoryImpl: BusinessModeRepository {
    private let store: AnyStorage<UserDefaultsStore>
    private let environment: String
    private let lock = NSRecursiveLock()
    private let subject: CurrentValueSubject<BusinessMode, Never>

    init(store: AnyStorage<UserDefaultsStore>, environment: String) {
        self.store = store
        self.environment = environment
        let selections: [String: BusinessMode] = store.get(.businessModes) ?? [:]
        subject = .init(selections[environment] ?? .ordinary)
    }

    var mode: BusinessMode { lock.withLock { subject.value } }
    var changes: AnyPublisher<BusinessMode, Never> { subject.eraseToAnyPublisher() }

    func select(_ mode: BusinessMode) {
        lock.withLock {
            var selections: [String: BusinessMode] = store.get(.businessModes) ?? [:]
            selections[environment] = mode
            store.set(selections, key: .businessModes)
            subject.send(mode)
        }
    }
}
