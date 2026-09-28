//
//  NotificationsMapper.swift
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
import DatabaseKit
import RestClient

struct NotificationsMapper: NotificationsMapperProtocol {
    // MARK: - Dependencies
    private let transactionsMapper: TransactionsMapperProtocol

    // MARK: - Init
    init(transactionsMapper: TransactionsMapperProtocol) {
        self.transactionsMapper = transactionsMapper
    }

    // MARK: - DTO -> Domain
    private func toDomain(dto: ResponseModels.Notification.NotificationType) -> Notifications.NotificationType {
        switch dto {
            case .transactionPending:
                return .transactionPending
            case .transactionAccepted:
                return .transactionAccepted
            case .transactionRejected:
                return .transactionRejected
            case .transactionExpired:
                return .transactionExpired
            case .geodataMissing:
                return .geodataMissing
        }
    }

    private func toDomain(dto: ResponseModels.Notification.Status) -> Notifications.Status {
        switch dto {
            case .pending:
                return .pending
            case .read:
                return .read
        }
    }

    func toDomain(dto: ResponseModels.Notification) -> Notifications.Model {
        .init(
            id: dto.id,
            data: transactionsMapper.toDomain(from: dto.data.transaction),
            createdAt: dto.createdAt,
            type: toDomain(dto: dto.type),
            status: toDomain(dto: dto.status)
        )
    }

    // MARK: - Database -> Domain
    private func toDomain(from dbModel: DatabaseKit.Notification.NotificationType) -> Notifications.NotificationType {
        switch dbModel {
            case .transactionPending:
                return .transactionPending
            case .transactionAccepted:
                return .transactionAccepted
            case .transactionRejected:
                return .transactionRejected
            case .transactionExpired:
                return .transactionExpired
            case .geodataMissing:
                return .geodataMissing
        }
    }

    private func toDomain(from dbModel: DatabaseKit.Notification.Status) -> Notifications.Status {
        switch dbModel {
            case .pending:
                return .pending
            case .read:
                return .read
        }
    }

    func toDomain(from dbModel: DatabaseKit.Notification) -> Notifications.Model {
        .init(
            id: dbModel.id,
            data: transactionsMapper.toDomain(from: dbModel.transactionNode),
            createdAt: dbModel.createdAt,
            type: toDomain(from: dbModel.type),
            status: toDomain(from: dbModel.status)
        )
    }

    // MARK: - Domain -> Database
    private func toDatabase(from dModel: Notifications.NotificationType) -> DatabaseKit.Notification.NotificationType {
        switch dModel {
            case .transactionPending:
                return .transactionPending
            case .transactionAccepted:
                return .transactionAccepted
            case .transactionRejected:
                return .transactionRejected
            case .transactionExpired:
                return .transactionExpired
            case .geodataMissing:
                return .geodataMissing
        }
    }

    private func toDatabase(from dModel: Notifications.Status) -> DatabaseKit.Notification.Status {
        switch dModel {
            case .pending:
                return .pending
            case .read:
                return .read
        }
    }

    func toDatabase(from dModel: Notifications.Model) -> DatabaseKit.Notification {
        .init(
            id: dModel.id,
            createdAt: dModel.createdAt,
            type: toDatabase(from: dModel.type),
            status: toDatabase(from: dModel.status),
            transactionNode: transactionsMapper.toDatabaseNode(from: dModel.data)
        )
    }
}
