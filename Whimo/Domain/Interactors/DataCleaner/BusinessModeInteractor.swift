//
//  BusinessModeInteractor.swift
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

enum BusinessModeError: Error {
    case synchronizationRequired
}

protocol BusinessModeInteractor: AnyObject {
    var mode: BusinessMode { get }
    var changes: AnyPublisher<BusinessMode, Never> { get }
    func checkEntry() async throws
    func switchMode(to mode: BusinessMode) async throws
}

actor BusinessModeInteractorImpl: BusinessModeInteractor {
    private let repository: BusinessModeRepository
    private let cleaner: DataCleanerInteractor
    private let appState: AppState
    private var isSwitching = false

    init(repository: BusinessModeRepository, cleaner: DataCleanerInteractor, appState: AppState) {
        self.repository = repository
        self.cleaner = cleaner
        self.appState = appState
    }

    nonisolated var mode: BusinessMode { repository.mode }
    nonisolated var changes: AnyPublisher<BusinessMode, Never> { repository.changes }

    func checkEntry() async throws {
        if try await cleaner.hasUnsynchronizedWork() { throw BusinessModeError.synchronizationRequired }
    }

    func switchMode(to target: BusinessMode) async throws {
        guard !isSwitching, target != repository.mode else { return }

        isSwitching = true
        defer { isSwitching = false }
        try await cleaner.resetBusinessData(protectingUnsynchronizedWork: target == .test) { [repository, appState] in
            repository.select(target)
            appState.system[\.selectedTab] = .settings
        }
        await MainActor.run {
            guard repository.mode == target, appState.profile.value.userModel.value != nil else { return }

            appState.navigation.send(.authorized)
        }
    }
}
