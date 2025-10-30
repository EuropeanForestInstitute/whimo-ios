//
//  NotificationsListViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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

import SwiftUI
import Combine
import RestClient
import Utility

private typealias Module = NotificationsListModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        enum ListLoader {
            case top
            case bottom
        }

        // MARK: - Public Properties
        @Published var selectedFilter: NotificationFilter = .all
        @Published private(set) var notifications: Loadable<IdentifiedArrayOf<Notifications.Model>> = .notRequested
        @Published private(set) var showBottomLoader = false

        var filters: IdentifiedArrayOf<NotificationFilter> { .init(uniqueElements: NotificationFilter.allCases) }

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()
        private var listLoader: ListLoader?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.notificationsService) private var notificationsService

        // MARK: - Init
        init() {
            setupBindings()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didPullRefresh() async {
            let refreshTask = Task { [weak self] in
                guard let self else { return }

                self.listLoader = .top
                defer { self.listLoader = nil }

                await self.fetchNotificationsRequest(selectedFilter: self.selectedFilter, refresh: true)
            }

            _ = await refreshTask.result
        }

        func didPullLoadNextPage() async {
            let pagination = appState.notifications.value.pagination
            guard pagination?.hasNextPage == true else { return }

            self.listLoader = .bottom
            defer { self.listLoader = nil }

            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = true
                }
            }

            await fetchNotificationsRequest(selectedFilter: selectedFilter, refresh: false)
            await MainActor.run { [weak self] in
                withAnimation(.snappy) {
                    self?.showBottomLoader = false
                }
            }
        }

        func didTapOpenDetails(item: Notifications.Model) {
            let transactionId = item.data.id
            let screen: Screen = .transactionDetails(transactionId: transactionId)
            appState.navigation[\.path].append(.push(screen))
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBindings() {
        Publishers.Merge(
            appState.notifications.state
                .map(\.cachedList)
                .removeDuplicates(),
            appState.notifications.state
                .map(\.list)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notifications in
            guard let self else { return }

//            log.debug("[notifications]: \(notifications.desc), count: \(notifications.value?.count ?? -999)")
            // handle loader
            switch notifications {
                case .notRequested, .requested:
                    break
                case .isLoading:
                    if self.listLoader != nil { break }
                    self.appState.system[\.isLoading] = true
                case .loaded, .failed:
                    self.appState.system[\.isLoading] = false
            }

            // handle datasource
            switch notifications {
                case .requested(let lastValue):
                    self.notifications = .requested(lastValue: lastValue)
                case .isLoading(let lastValue):
                    let lastValue = lastValue ?? self.notifications.value // cache items usage
                    self.notifications = .isLoading(lastValue: lastValue)
                case .loaded(let value):
                    self.notifications = .loaded(value: value)
                case .failed(let error):
                    appState.showError(message: error.localizedDescription)
                default:
                    break
            }
        }
        .store(in: cancellable)
        $selectedFilter
            .scan((selectedFilter, selectedFilter)) { prev, current -> (Module.NotificationFilter, Module.NotificationFilter) in
                (prev.1, current)
            }
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] prev, current in
                guard
                    let self,
                    current != prev
                else { return }

                Task {
                    self.appState.system[\.isLoading] = true
                    defer { self.appState.system[\.isLoading] = false }

                    let filter = current
                    await self.fetchNotificationsRequest(selectedFilter: filter, refresh: true)
                }
            }
            .store(in: cancellable)
    }

    func startup() {
        UNUserNotificationCenter.current().setBadgeCount(.zero)
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            await fetchNotificationsRequest(selectedFilter: .all, refresh: true)
        }
    }

    // MARK: - Common
    func fetchNotificationsRequest(
        selectedFilter: Module.NotificationFilter,
        refresh: Bool
    ) async {
        let notificationTypes: [RequestModels.NotificationsList.NotificationType]
        switch selectedFilter {
            case .all:
                notificationTypes = []
            case .requireActions:
                notificationTypes = RequestModels.NotificationsList.NotificationType.requireActions
        }

        try? await notificationsService.fetchNotifications(
            notificationTypes: notificationTypes,
            refresh: refresh
        )
    }
}
