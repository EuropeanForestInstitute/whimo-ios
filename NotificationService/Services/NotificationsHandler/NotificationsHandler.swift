//
//  NotificationsHandler.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 16.07.2025.
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
import Targets
import Utility
import Resources

private typealias Localization = AppLocale.General.NotificationsService

// MARK: - NotificationsHandler
actor NotificationsHandler {
    struct Update: Sendable {
        static var defaultMesage: Self = .init(title: "", body: Localization.DefaultEvent.body)

        let title: String
        let body: String
    }

    // MARK: - Dependencies
    @Inject(\.transactionsTarget) private var transactionsTarget

    // MARK: - Public Methods
    func handle(notification: UserNotificationsService.Event.TransactionUpdate) async -> Update {
        do {
            let notificationPush = try notification.aps.alert.toModel()
            let title = notificationPush.type.title

            do {
                let transactionId = notificationPush.data.transaction.id
                let request: RequestModels.GetTransaction = .init(transactionId: transactionId)
                let response = try await transactionsTarget.getTransaction(request)
                let body = "\(response.data.commodity.code) \(response.data.commodity.name), \(response.data.volume)\(response.data.commodity.unit)"
                let update: Update = .init(title: title, body: body)

                return update
            } catch {
                log.error(error.localizedDescription)
                return .defaultMesage
            }
        } catch {
            log.error(error.localizedDescription)
            return .defaultMesage
        }
    }
}
