//
//  NotificationsSettingsMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.07.2025.
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

struct NotificationsSettingsMapper: NotificationsSettingsMapperProtocol {
    // MARK: - DTO -> Domain
    private func toDomain(dto: ResponseModels.NotificationsSettings.SettingsType) -> NotificationsSettingsModel.SettingsType {
        switch dto {
            case .geodataMissing:
                .geodataMissing
            case .geodataUpdated:
                .geodataUpdated
            case .transactionAccepted:
                .transactionAccepted
            case .transactionExpired:
                .transactionExpired
            case .transactionPending:
                .transactionPending
            case .transactionRejected:
                .transactionRejected
        }
    }

    func toDomain(dto: ResponseModels.NotificationsSettings) -> NotificationsSettingsModel {
        .init(type: toDomain(dto: dto.type), isEnabled: dto.isEnabled)
    }

    // MARK: - Database -> Domain
    private func toDomain(from dbModel: DatabaseKit.NotificationsSettings.SettingsType) -> NotificationsSettingsModel.SettingsType {
        switch dbModel {
            case .geodataMissing:
                .geodataMissing
            case .geodataUpdated:
                .geodataUpdated
            case .transactionAccepted:
                .transactionAccepted
            case .transactionExpired:
                .transactionExpired
            case .transactionPending:
                .transactionPending
            case .transactionRejected:
                .transactionRejected
        }
    }

    func toDomain(from dbModel: DatabaseKit.NotificationsSettings) -> NotificationsSettingsModel {
        .init(type: toDomain(from: dbModel.type), isEnabled: dbModel.isEnabled)
    }

    // MARK: - Domain -> Database
    private func toDatabase(from dModel: NotificationsSettingsModel.SettingsType) -> DatabaseKit.NotificationsSettings.SettingsType {
        switch dModel {
            case .geodataMissing:
                .geodataMissing
            case .geodataUpdated:
                .geodataUpdated
            case .transactionAccepted:
                .transactionAccepted
            case .transactionExpired:
                .transactionExpired
            case .transactionPending:
                .transactionPending
            case .transactionRejected:
                .transactionRejected
        }
    }

    func toDatabase(from dModel: NotificationsSettingsModel) -> DatabaseKit.NotificationsSettings {
        .init(type: toDatabase(from: dModel.type), isEnabled: dModel.isEnabled)
    }
}
