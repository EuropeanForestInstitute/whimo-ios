//
//  DataCleanerInteractorImpl.swift
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
import DatabaseKit
import StorageKit

final class DataCleanerInteractorImpl: DataCleanerInteractor {
    // MARK: - Dependencies
    private let appState: AppState
    private let database: DatabaseKit.Database
    private let authRepository: AuthRepository
    private let profileCachingRepository: ProfileCachingRepository
    private let keychainStore: AnyStorage<KeychainStore>
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>

    // MARK: - Init
    init(
        appState: AppState,
        database: DatabaseKit.Database,
        authRepository: AuthRepository,
        profileCachingRepository: ProfileCachingRepository,
        keychainStore: AnyStorage<KeychainStore>,
        userDefaultsStore: AnyStorage<UserDefaultsStore>
    ) {
        self.appState = appState
        self.database = database
        self.authRepository = authRepository
        self.profileCachingRepository = profileCachingRepository
        self.keychainStore = keychainStore
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - DataCleanerInteractor
    func dropAll() async throws {
        dropAppState()
        dropServices()
        try await dropDatabase()
    }
}

// MARK: - Private Methods
private extension DataCleanerInteractorImpl {
    func dropAppState() {
        appState.system.dispatch { state in
            state = .initialState
        }
        appState.transactions.dispatch { state in
            state = .initialState
        }
        appState.createTransaction.dispatch { state in
            state = .initialState
        }
        appState.createPassword.dispatch { state in
            state = .initialState
        }
        appState.notifications.dispatch { state in
            state = .initialState
        }
        appState.profile.dispatch { state in
            state = .initialState
        }
    }

    func dropDatabase() async throws {
        try await database.flush()
    }

    func dropServices() {
        authRepository.flush()
        profileCachingRepository.flush()
        keychainStore.clear()
        userDefaultsStore.clear()
    }
}
