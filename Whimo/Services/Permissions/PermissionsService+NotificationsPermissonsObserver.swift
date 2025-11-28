//
//  PermissionsService+NotificationsPermissonObserver.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.07.2025.
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
import UserNotifications
import Combine
import Utility

private typealias NotificationsPermissonsObserver = PermissionsService.NotificationsPermissonObserver

// MARK: - NotificationsPermissonObserver
extension PermissionsService {
    final class NotificationsPermissonObserver {
        // MARK: - Properties
        var statusPublisher: AnyPublisher<UNAuthorizationStatus, Never> {
            _statusSubject.eraseToAnyPublisher()
        }

        // MARK: - Private Properties
        private let _statusSubject: CurrentValueSubject<UNAuthorizationStatus, Never> = .init(.notDetermined)

        // MARK: - Dependencies
        private let notificationCenter: UNUserNotificationCenter
        private var cancellable: CancelBag = .init()

        // MARK: - Init
        init(notificationCenter: UNUserNotificationCenter) {
            self.notificationCenter = notificationCenter

            setupBinding()

            Task { [weak self] in
                await self?.fetchStatus()
            }
        }

        // MARK: - Private Methods
        @discardableResult
        func fetchStatus() async -> UNAuthorizationStatus {
            let status = await notificationCenter.notificationSettings()
            let permissionStatus = status.authorizationStatus
            _statusSubject.send(permissionStatus)

            return permissionStatus
        }
    }
}

// MARK: - Private Methods
private extension NotificationsPermissonsObserver {
    // MARK: - Setup
    func setupBinding() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                log.debug("Entered foreground. Fetching notification status permission.")

                Task { [weak self] in
                    await self?.fetchStatus()
                }
            }
            .store(in: cancellable)
    }
}
