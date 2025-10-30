//
//  RootViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 29.04.2025.
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

private typealias Module = RootModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var isLoading: Bool = false
        let navigationHandler: CoordinatorModule.NavigationHandler<Screen>

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.connectivity) private var connectivity
        @Inject(\.userDefaultsStore) private var userDefaultsStore
        @Inject(\.profileLocalRepository) private var profileLocalRepository
        @Inject(\.dataCleanerService) private var dataCleanerService
        @Inject(\.userNotificationsService) private var userNotificationsService
        @Inject(\.stateRegistryService) private var stateRegistryService
        @Inject(\.offlineTransactionsSyncService) private var offlineTransactionsSyncService

        // MARK: - Init
        init() {
            self.navigationHandler = NavigationBuilder.buildNavigationHandler()

            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.system.state
            .map(\.isLoading)
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.isLoading)
            .store(in: cancellable)
        userNotificationsService.tappedEvents
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handleDidTapNotification)
            .store(in: cancellable)
        appState.navigation.activity
            .filter { $0 == .authorized }
            .sink { [weak self] _ in
                guard let self else { return }

                Task {
                    await self.preloadData()
                }
            }
            .store(in: cancellable)
    }

    func setupNavigation() {
        log.debug()
        let user = try? profileLocalRepository.fetchProfile()
        if user != nil {
            appState.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
            appState.navigation.send(.authorized)
            log.debug("user authorized")
        } else {
            appState.navigation[\.path] = [.root(.login, embedInNavigationView: true)]
            log.debug("user not authorized")
        }
    }

    func startup() {
        Task { [weak self] in
            await self?.dropUserDataIfNeeded()
            self?.setupNavigation()
        }
    }

    // MARK: - Common
    func dropUserDataIfNeeded() async {
        let isLoggedIn: Bool = userDefaultsStore.get(.isLoggedIn) ?? false
        let user = try? profileLocalRepository.fetchProfile()
        guard
            !isLoggedIn,
            user != nil
        else { return }

        try? await dataCleanerService.dropAll()
    }

    func handleDidTapNotification(event: UserNotificationsService.Event) {
        switch event {
            case .transactionUpdate:
                appState.navigation[\.path].append(.push(.notificationsList))
            case .unknown:
                log.debug("An unknown event received. Event:\(event)")
        }
    }

    func startTransactionsSyncObserver() {
        connectivity.isReachable
            .removeDuplicates()
            .sink { [weak self] status in
                guard let self else { return }

                switch status {
                    case .reachable:
                        Task {
                            try await self.offlineTransactionsSyncService.syncTransactions()
                        }
                    default:
                        return
                }
            }
            .store(in: cancellable)
    }

    func preloadData() async {
        await stateRegistryService.loadCacheData()
        startTransactionsSyncObserver()
        await stateRegistryService.fetchRemoteData()
    }
}
