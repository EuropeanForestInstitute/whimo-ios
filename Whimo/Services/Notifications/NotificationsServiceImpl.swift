//
//  NotificationsServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 24.06.2025.
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
import Utility

final class NotificationsServiceImpl: NotificationsService {
    // MARK: - Dependencies
    private let appState: AppState
    private let notificationsCachingRepository: any NotificationsCachingRepository

    // MARK: - Init
    init(
        appState: AppState,
        notificationsCachingRepository: any NotificationsCachingRepository
    ) {
        self.appState = appState
        self.notificationsCachingRepository = notificationsCachingRepository
    }

    // MARK: - NotificationsService
    func fetchNotifications(
        notificationTypes: [RequestModels.NotificationsList.NotificationType],
        refresh: Bool
    ) async throws {
        let oldPagination = appState.notifications.value.pagination
        let pagination: NotificationsPagination

        if !refresh, let oldPagination {
            pagination = .init(
                notificationTypes: notificationTypes,
                pageData: .init(
                    page: oldPagination.pageData.page + 1,
                    pageSize: oldPagination.pageData.pageSize
                )
            )
        } else {
            pagination = .initial(notificationTypes: notificationTypes)
        }

        appState.notifications.dispatch { state in
            state.list.setIsLoading()
        }
        do {
            let responseData = try await notificationsCachingRepository.fetchNotifications(with: pagination)
            let updatedPageData: PaginationRequest = .init(
                page: responseData.pagination.nextPage == nil ? oldPagination?.pageData.page ?? PaginationRequest.initial.page : pagination.pageData.page,
                pageSize: pagination.pageData.pageSize
            )
            var updatedPagination: NotificationsPagination = .init(
                notificationTypes: notificationTypes,
                pageData: updatedPageData
            )
            updatedPagination.nextPage = responseData.pagination.nextPage

            let currentList: IdentifiedArrayOf<Notifications.Model> = refresh ? .init() : appState.notifications.value.list.value ?? []
            let updatedList = currentList + responseData.list

            appState.notifications.dispatch { state in
                state.list = .loaded(value: updatedList)
                state.pagination = updatedPagination
            }
        } catch {
            appState.notifications.dispatch { state in
                state.list = .failed(error: error)
            }
            throw error
        }
    }
}
