//
//  UserNotificationsService.swift
//  Whimo
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

import UIKit
import Combine
import UserNotifications
import Utility

// MARK: - UserNotificationsService
class UserNotificationsService: NSObject, UserNotificationsServiceProtocol {
    // MARK: - Public Properties
    var presentedEvents: AnyPublisher<UserNotificationsService.Event, Never> {
        _presentedEvents.eraseToAnyPublisher()
    }
    var tappedEvents: AnyPublisher<UserNotificationsService.Event, Never> {
        _tappedEvents.eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var _presentedEvents: CurrentValueSubject<UserNotificationsService.Event, Never> = .init(.unknown(value: nil))
    private var _tappedEvents: CurrentValueSubject<UserNotificationsService.Event, Never> = .init(.unknown(value: nil))

    // MARK: - Dependencies

    // MARK: - Init
    override init() {
        super.init()
    }

    // MARK: - UserNotificationsServiceProtocol
    func removeNotifications(withIdentifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: withIdentifiers)
    }

    func removeEvents() {
        _tappedEvents.send(.unknown(value: nil))
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Private Methods
private extension UserNotificationsService { }

// MARK: - UNUserNotificationCenterDelegate
extension UserNotificationsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // handle fcm event
        let userInfo = notification.request.content.userInfo
        log.debug("userInfo: \(userInfo)")

        do {
            let event: Event = try .init(from: userInfo)
            log.debug("event: \(event)")

            switch event {
                case .transactionUpdate(let transactionUpdate):
                    let notificationPush = try transactionUpdate.aps.alert.toModel()
                    log.debug("notificationPush: \(notificationPush)")
                case .unknown(let value):
                    log.debug("an unknown notificationPush: \(String(describing: value))")
            }

            _presentedEvents.send(event)
            switch event {
                default:
                    completionHandler([.banner, .badge, .sound, .list])
            }
            return
        } catch {
            log.error("\(error.localizedDescription)")
        }

        completionHandler([.banner, .badge, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        log.debug("userInfo: \(response.notification.request.content.userInfo)")
        log.debug("request.identifier: \(response.notification.request.identifier)")
        let userInfo = response.notification.request.content.userInfo
        do {
            let event: Event = try .init(from: userInfo)
            log.debug("event: \(event)")
            _tappedEvents.send(event)
        } catch {
            log.error("\(error.localizedDescription)")
        }
        completionHandler()
    }
}
