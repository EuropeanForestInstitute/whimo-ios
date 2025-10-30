//
//  NotificationsCacheServiceImpl.swift
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
import RestClient

final class NotificationsCacheServiceImpl: NotificationsCacheService {
    // MARK: - Dependencies
    private let appState: AppState
    private let localRepo: any NotificationsLocalRepository

    // MARK: - Init
    init(appState: AppState, localRepo: any NotificationsLocalRepository) {
        self.appState = appState
        self.localRepo = localRepo
    }

    // MARK: - NotificationsCacheService
    func fetchNotifications() async throws {
        appState.notifications.dispatch { state in
            state.cachedList.setIsLoading()
        }
        do {
            let pagination: RequestModels.NotificationsList = .initial()
            let notifications = try await localRepo.fetchNotifications(with: pagination)

            appState.notifications.dispatch { state in
                let list = notifications.list
                if !list.isEmpty {
                    state.cachedList = .requested(lastValue: list)
                } else {
                    state.cachedList = .requested(lastValue: nil)
                }
            }
        } catch {
            appState.notifications.dispatch { state in
                state.cachedList = .failed(error: error)
            }
            throw error
        }
    }
}
