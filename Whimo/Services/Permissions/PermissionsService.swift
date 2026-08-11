//
//  PermissionsService.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.05.2025.
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
import UserNotifications
import CoreLocation
import Combine
import Contacts
import Utility
import Extensions

// MARK: - PermissionsService
final class PermissionsService: NSObject, PermissionsServiceProtocol {
    // MARK: - LocationAuthorization
    enum LocationAuthorization {
        case authorizedWhenInUse
        case authorizedAlways
    }

    // MARK: - Public Properties
    var locationPermissionStatusValue: CLAuthorizationStatus {
        _locationPermissionsStatus.value
    }

    var locationPermissionsStatus: AnyPublisher<CLAuthorizationStatus, Never> {
        _locationPermissionsStatus.eraseToAnyPublisher()
    }
    var notificationsPermissonsStatus: AnyPublisher<UNAuthorizationStatus, Never> {
        notificationsPermissonObserver.statusPublisher.eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var continuation: CheckedContinuation<CLAuthorizationStatus?, Never>?
    private let _locationPermissionsStatus: CurrentValueSubject<CLAuthorizationStatus, Never> = .init(.notDetermined)
    private let contactStore: CNContactStore

    // MARK: - Dependencies
    private let notificationCenter: UNUserNotificationCenter
    private let locationManager: CLLocationManager
    private let notificationsPermissonObserver: NotificationsPermissonObserver

    // MARK: - Init
    init(
        notificationCenter: UNUserNotificationCenter,
        locationManager: CLLocationManager = .init(),
        contactStore: CNContactStore = .init()
    ) {
        self.notificationCenter = notificationCenter
        self.locationManager = locationManager
        self.contactStore = contactStore
        self.notificationsPermissonObserver = .init(notificationCenter: notificationCenter)

        super.init()

        self.locationManager.delegate = self
    }

    // MARK: - PermissionsServiceProtocol
    @discardableResult
    func requestNotifications() async -> UNAuthorizationStatus {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return .notDetermined }

            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
                log.debug("Notification permissions granted")
            }
        } catch {
            log.debug(error.localizedDescription)
            return .notDetermined
        }

        let status = await notificationsPermissonObserver.fetchStatus()
        return status
    }

    @discardableResult
    func requestLocations(upTo type: LocationAuthorization) async -> CLAuthorizationStatus? {
        switch type {
            case .authorizedWhenInUse:
                return await requestLocations(.authorizedWhenInUse)
            case .authorizedAlways:
                _ = await requestLocations(.authorizedWhenInUse)
                let task = Task { [weak self] in
                    await self?.requestLocations(.authorizedAlways)
                }

                return await task.value
        }
    }

    @discardableResult
    func requestContacts() async -> CNAuthorizationStatus {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            let status = CNContactStore.authorizationStatus(for: .contacts)

            if granted {
                log.debug("Contacts permission granted, status: \(status.description)")
            } else {
                log.debug("Contacts permission denied, status: \(status.description)")
            }

            return status
        } catch {
            log.error("Failed to request contacts permission: \(error.localizedDescription)")
            return CNContactStore.authorizationStatus(for: .contacts)
        }
    }
}

// MARK: - Private Methods
private extension PermissionsService {
    @discardableResult
    func requestLocations(_ type: LocationAuthorization) async -> CLAuthorizationStatus? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch type {
                case .authorizedWhenInUse:
                    let authorizationStatus = self.locationManager.authorizationStatus
                    if authorizationStatus != .notDetermined {
                        continuation.resume(with: .success(authorizationStatus))
                        self.continuation = nil
                    } else {
                        self.locationManager.requestWhenInUseAuthorization()
                    }
                case .authorizedAlways:
                    log.debug("locationService.authorizationStatus: \(locationManager.authorizationStatus)")
                    if locationManager.authorizationStatus != .notDetermined && locationManager.authorizationStatus != .authorizedWhenInUse {
                        continuation.resume(with: .success(locationManager.authorizationStatus))
                        self.continuation = nil
                    } else {
                        self.locationManager.requestAlwaysAuthorization()
                    }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionsService: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        log.debug("status: \(status.description)")

        self.continuation?.resume(returning: status)
        continuation = nil

        _locationPermissionsStatus.send(status)
    }
}
