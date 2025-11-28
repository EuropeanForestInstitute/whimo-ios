//
//  NavBarViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

import UIKit
import Utility

private typealias Module = NavBarModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var showNotificationsBadge: Bool = false
        private(set) var screensCount: Int

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.userNotificationsService) private var userNotificationsService
        @Inject(\.notificationsInteractor) private var notificationsInteractor

        // MARK: - Init
        init() {
            @Inject(\.appState) var appState
            self.screensCount = appState.navigation.value.path.count

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
        userNotificationsService.presentedEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: cancellable)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: cancellable)
        appState.notifications.state
            .map(\.list)
            .map { !($0.value?.isEmpty ?? true) }
            .weakAssign(on: self, to: \.showNotificationsBadge)
            .store(in: cancellable)
    }

    func startup() { }
}
