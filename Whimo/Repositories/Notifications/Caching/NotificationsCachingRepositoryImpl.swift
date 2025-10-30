//
//  NotificationsCachingRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.07.2025.
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

final class NotificationsCachingRepositoryImpl: NotificationsCachingRepository {
    // MARK: - Dependencies
//    private let transactionLocalRepo: any TransactionsLocalRepository
    private let localRepo: any NotificationsLocalRepository
    private let remoteRepo: any NotificationsRemoteRepository

    // MARK: - Init
    init(
        transactionLocalRepo: any TransactionsLocalRepository,
        localRepo: any NotificationsLocalRepository,
        remoteRepo: any NotificationsRemoteRepository
    ) {
//        self.transactionLocalRepo = transactionLocalRepo
        self.localRepo = localRepo
        self.remoteRepo = remoteRepo
    }

    // MARK: - NotificationsCachingRepository
    func fetchNotifications(with pagination: NotificationsPagination) async throws -> NotificationsData {
        do {
            let notifications = try await remoteRepo.fetchNotifications(with: pagination)

            for notification in notifications.list {
//                try await transactionLocalRepo.save(notification.data)
                try await localRepo.save(notification)
            }

            return notifications
        } catch {
            throw error
        }
    }
}
