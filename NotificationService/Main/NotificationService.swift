//
//  NotificationService.swift
//  NotificationService
//
//  Created by Vyacheslav Razumeenko on 14.07.2025.
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

import UserNotifications
import Utility

class NotificationService: UNNotificationServiceExtension {
    // MARK: - Properties
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    // MARK: - Dependencies
    private lazy var startupService: StartupService = .init()
    private lazy var transactionUpdateHandler: TransactionUpdateHandler = .init()

    override init() {
        super.init()

        startup()
    }

    // MARK: - UNNotificationServiceExtension
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            let userInfo = request.content.userInfo
            log.debug("userInfo: \(userInfo)")

            Task { [weak self] in
                guard let self else { return }

                do {
                    let event: UserNotificationsService.Event = try .init(from: userInfo)
                    try await self.handleNotificationEvent(event, bestAttemptContent: bestAttemptContent)
                } catch {
                    log.error("\(error.localizedDescription)")
                }

                contentHandler(bestAttemptContent)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

// MARK: - Private Methods
private extension NotificationService {
    // MARK: - Setup
    func startup() {
        log.debug()
        Task { [weak self] in
            await self?.startupService.initNetworking()
        }
    }

    // MARK: - Common
    func handleNotificationEvent(
        _ event: UserNotificationsService.Event,
        bestAttemptContent: UNMutableNotificationContent
    ) async throws {
        switch event {
            case .transactionUpdate(let notification):
                log.debug("notification: \(notification)")

                let update = await transactionUpdateHandler.handle(notification: notification)
                bestAttemptContent.title = update.title
                bestAttemptContent.body = update.body
            case .unknown:
                break
        }
    }
}
