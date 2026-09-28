//
//  LocationService.swift
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

import Foundation
import UIKit
import CoreLocation
import Combine
import StorageKit
import Utility
import Resources

// MARK: - LocationService
class LocationService: NSObject, LocationServiceProtocol {
    private enum Constants {
        static let logSeparator = "📍"
    }

    // MARK: - Properties
    var lastLocationPublisher: AnyPublisher<CLLocation, Never> {
        _lastLocation.eraseToAnyPublisher()
    }
    var lastLocation: CLLocation {
        _lastLocation.value
    }
    var desiredAccuracy: CLLocationAccuracy {
        locationManager.desiredAccuracy
    }

    // MARK: - Private Properties
    private var _lastLocation: CurrentValueSubject<CLLocation, Never> = .init(.init())
    private var bgTask = UIBackgroundTaskIdentifier.invalid

    // MARK: - Dependencies
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>
    private let permissionsService: PermissionsServiceProtocol
    private var locationManager: CLLocationManager

    // MARK: - Init
    init(
        userDefaultsStore: AnyStorage<UserDefaultsStore>,
        permissionsService: PermissionsServiceProtocol
    ) {
        self.userDefaultsStore = userDefaultsStore
        self.permissionsService = permissionsService
        self.locationManager = CLLocationManager()
        super.init()

        initialSetup()
    }

    // MARK: - LocationServiceProtocol
    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
        log.debug(Constants.logSeparator)
    }

    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        log.debug(Constants.logSeparator)
    }

    func startUpdatingBGLocation() {
        locationManager.distanceFilter = 5
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.showsBackgroundLocationIndicator = true
    }

    func stopUpdatingBGLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopMonitoringVisits()
        self.locationManager.distanceFilter = kCLDistanceFilterNone
    }

    func getUserLocation() async -> CLLocation? {
        switch permissionsService.locationPermissionStatusValue {
            case .notDetermined, .restricted, .denied:
                return nil
            case .authorizedAlways, .authorizedWhenInUse:
                break
            @unknown default:
                return nil
        }

        self.startUpdatingLocation()

        var userLocation: CLLocation?

        for await value in self.lastLocationPublisher.dropFirst().values
        where value != .init(latitude: .zero, longitude: .zero) {
            userLocation = value
            break
        }

        self.stopUpdatingLocation()

        return userLocation
    }

    func getPlace(for location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
//        let currentLocalize: LocalizeKeys = self.userDefaultsStore.get(.currentLocalize) ?? .english

        let currentLocalizeString: String = self.userDefaultsStore.get(.currentLocalize) ?? LocalizeKeys.english.code
        guard let currentLocalize: LocalizeKeys = .init(rawValue: currentLocalizeString) else { return nil }

        log.debug("currentLocalize: \(currentLocalize)")
        let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: currentLocalize.locale)

        return placemarks.first
    }

    func getCurrentPlace() async -> CLPlacemark? {
        guard let userLocation = await self.getUserLocation() else { return nil }

        let place = try? await self.getPlace(for: userLocation)

        return place
    }

    func setLowAccuracy() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func setBestAccuracy() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
}

// MARK: - Private Methods
private extension LocationService {
    func initialSetup() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.bgTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskIdentifier.invalid
        }

        guard let location = locations.last else { return }

        self._lastLocation.send(location)
        log.debug("\(Constants.logSeparator) lastLocation: \(location)")
        UIApplication.shared.endBackgroundTask(self.bgTask)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        self.startUpdatingBGLocation()
    }
}
