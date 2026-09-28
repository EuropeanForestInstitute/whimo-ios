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
import GRDB
import DatabaseKit
import StorageKit

actor DataCleanerInteractorImpl: DataCleanerInteractor {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let dataFetcherInteractor: DataFetcherInteractor
    private let appState: AppState
    private let database: DatabaseKit.Database
    private let fileStorage: FileStorageServiceProtocol
    private let authRepository: AuthRepository
    private let offlineTransactionsSyncInteractor: OfflineTransactionsSyncInteractor
    private let keychainStore: AnyStorage<KeychainStore>
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>

    private let businessModeRepository: BusinessModeRepository?

    private var cleanupTask: Task<Void, Error>?

    // MARK: - Init
    init(
        appState: AppState,
        dataFetcherInteractor: DataFetcherInteractor,
        database: DatabaseKit.Database,
        fileStorage: FileStorageServiceProtocol,
        authRepository: AuthRepository,
        offlineTransactionsSyncInteractor: OfflineTransactionsSyncInteractor,
        keychainStore: AnyStorage<KeychainStore>,
        userDefaultsStore: AnyStorage<UserDefaultsStore>,
        businessDataContext: BusinessDataContext = .init(),
        businessModeRepository: BusinessModeRepository? = nil
    ) {
        self.businessModeRepository = businessModeRepository
        self.businessDataContext = businessDataContext
        self.appState = appState
        self.dataFetcherInteractor = dataFetcherInteractor
        self.database = database
        self.fileStorage = fileStorage
        self.authRepository = authRepository
        self.offlineTransactionsSyncInteractor = offlineTransactionsSyncInteractor
        self.keychainStore = keychainStore
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - DataCleanerInteractor
    func resetBusinessData() async throws {
        try await clean(preservingSession: true)
    }

    func dropAll() async throws {
        try await clean(preservingSession: false)
    }

    func hasUnsynchronizedWork() async throws -> Bool {
        if businessDataContext.hasProtectedWork { return true }

        // Read the raw queue without catalogue joins or visible list filters.
        let records = try await database.readAll(DatabaseKit.Transaction.all())
        return records.contains { $0.persistingData.state == .onDisk }
    }

    func resetBusinessData(protectingUnsynchronizedWork: Bool, completion: @escaping @MainActor () -> Void) async throws {
        try await clean(preservingSession: true, protectingUnsynchronizedWork: protectingUnsynchronizedWork, completion: completion)
    }

    private func clean(
        preservingSession: Bool,
        protectingUnsynchronizedWork: Bool = false,
        completion: @escaping @MainActor () -> Void = {}
    ) async throws {
        // An overlapping Logout must complete its cleanup after the business reset.
        while let pending = cleanupTask { try? await pending.value }
        let task = Task {
            defer { cleanupTask = nil }
            try await performCleanup(preservingSession: preservingSession, protectingUnsynchronizedWork: protectingUnsynchronizedWork, completion: completion)
        }
        cleanupTask = task
        try await task.value
    }

    private func performCleanup(
        preservingSession: Bool,
        protectingUnsynchronizedWork: Bool,
        completion: @escaping @MainActor () -> Void
    ) async throws {
        try businessDataContext.beginReset(protectingUnsynchronizedWork: protectingUnsynchronizedWork)
        defer { businessDataContext.finishReset() }
        if protectingUnsynchronizedWork, try await hasUnsynchronizedWork() {
            throw BusinessModeError.synchronizationRequired
        }
        await dataFetcherInteractor.cancelCataloguePreparation()
        await offlineTransactionsSyncInteractor.discardPendingResults()
        if preservingSession {
            try await database.flushBusinessData()
            try fileStorage.removeAllQueuedData()
            let participant: UserModel? = keychainStore.get(.user)
            await MainActor.run {
                Self.dropBusinessState(appState, participant: participant)
                // A reset queued behind Logout cannot authorize the cleared session.
                if participant != nil {
                    completion()
                    appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
                }
            }
        } else {
            await MainActor.run { Self.dropAppState(appState) }
            dropServices()
            try await database.flush()
            try fileStorage.removeAllQueuedData()
        }
    }
}

// MARK: - Private Methods
private extension DataCleanerInteractorImpl {
    @MainActor
    static func dropBusinessState(_ appState: AppState, participant: UserModel?) {
        appState.system[\.isLoading] = false
        appState.profile[\.userModel] = participant.map { .loaded(value: $0) } ?? .notRequested
        appState.transactions.dispatch { $0 = .initialState }
        appState.balance.dispatch { $0 = .initialState }
        appState.createTransaction.dispatch { $0 = .init() }
        appState.notifications.dispatch { $0 = .initialState }
    }

    @MainActor
    static func dropAppState(_ appState: AppState) {
        dropBusinessState(appState, participant: nil)
        appState.notificationsSettings.dispatch { $0 = .initialState }
        appState.system.dispatch { $0 = .initialState }
        appState.createPassword.dispatch { $0 = .initialState }
        appState.profile.dispatch { $0 = .initialState }
    }

    func dropServices() {
        businessModeRepository?.select(.ordinary)
        authRepository.flush()
        keychainStore.clear()
        userDefaultsStore.clear()
    }
}
