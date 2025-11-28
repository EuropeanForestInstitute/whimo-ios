//
//  NotificationsLocalRepositoryImpl.swift
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
import DatabaseKit

final class NotificationsLocalRepositoryImpl: NotificationsLocalRepository {
    // MARK: - Dependencies
    private let database: any Database
    private let notificationsMapper: any NotificationsMapperProtocol

    // MARK: - Init
    init(
        database: any Database,
        notificationsMapper: any NotificationsMapperProtocol
    ) {
        self.database = database
        self.notificationsMapper = notificationsMapper
    }

    // MARK: - NotificationsLocalRepository
    // MARK: - Fetch
    func fetchNotifications(with pagination: NotificationsPagination) async throws -> NotificationsData {
        let fetchRequest = DatabaseKit.Notification.all()

        let limit = pagination.pageData.pageSize
        let currentPage = max(.zero, pagination.pageData.page - 1)
        let offset = limit * currentPage

        let totalCount: Int = try await database.readCount(fetchRequest)
        let dbModels = try await database.readAll(
            fetchRequest
                .limit(limit, offset: offset)
        )
        let domainModels: [Notifications.Model] = dbModels.map(notificationsMapper.toDomain)

        let page = pagination.pageData.page
        let totalPages: Int = (totalCount + limit - 1) / limit
        let previousPage: Int? = page > 1 ? page - 1 : nil
        let nextPage: Int? = page < totalPages ? page + 1 : nil

        let pagination: RestClient.Pagination = .init(
            pageSize: pagination.pageData.pageSize,
            nextPage: nextPage,
            previousPage: previousPage,
            count: totalCount,
            totalPages: totalPages,
            page: pagination.pageData.page
        )

        return (list: .init(uniqueElements: domainModels), pagination: pagination)
    }

    // MARK: - Save
    func save(_ model: Notifications.Model) async throws {
        let notification = notificationsMapper.toDatabase(from: model)

        try await database.save(notification)
    }
}
