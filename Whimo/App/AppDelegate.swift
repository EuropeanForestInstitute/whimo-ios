//
//  AppDelegate.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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
import UIKit
import FirebaseMessaging
import Utility

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Dependencies
    @Inject(\.database) private var database
    @Inject(\.tokenManager) private var tokenManager
    @Inject(\.firebaseService) private var firebaseService
    @Inject(\.remoteConfigService) private var remoteConfigService
    @Inject(\.userNotificationsService) private var userNotificationsService
    @Inject(\.tokenRegistryService) private var tokenRegistryService
    @Inject(\.userAgentService) private var userAgentService

    // MARK: - UIApplicationDelegate
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        log.debug()
        firebaseService.configure()
        remoteConfigService.configure()

        Task {
            await remoteConfigService.fetchAndActivate()
        }

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = userNotificationsService

        userAgentService.configure()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        log.debug()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        log.debug()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let stringDeviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        log.debug("Device Token: \(stringDeviceToken)")

        Messaging.messaging().apnsToken = deviceToken
        tokenRegistryService.updateDeviceToken(stringDeviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        log.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        log.debug("Firebase registration token: \(fcmToken ?? "empty token")")
        tokenRegistryService.updateFCMToken(fcmToken)
    }
}
