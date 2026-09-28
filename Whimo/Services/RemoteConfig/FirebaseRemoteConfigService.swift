//
//  FirebaseRemoteConfigService.swift
//  Whimo
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import FirebaseRemoteConfig
import Utility

// MARK: - FirebaseRemoteConfigService
final class FirebaseRemoteConfigService: RemoteConfigService {
    // MARK: - Private Properties
    private let client: RemoteConfigClient
    private let fetchLock: NSLock = .init()
    private var isFetchInProgress: Bool = false

    // MARK: - Init
    init(client: RemoteConfigClient = FirebaseRemoteConfigClient()) {
        self.client = client
    }

    // MARK: - RemoteConfigService
    var registrationPhoneRegionPolicy: RegistrationPhoneRegionPolicy {
        let value = client.stringValue(for: RemoteConfigKey.registrationPhoneRegionPolicy.rawValue)
        guard
            let data = value.data(using: .utf8),
            let policy = try? JSONDecoder().decode(RegistrationPhoneRegionPolicy.self, from: data)
        else {
            log.error("Remote Config registration phone region policy could not be decoded.")
            return RemoteConfigDefaults.registrationPhoneRegionPolicy
        }

        guard policy.schemaVersion == RegistrationPhoneRegionPolicy.supportedSchemaVersion else {
            log.error("Remote Config registration phone region policy schema is unsupported.")
            return RemoteConfigDefaults.registrationPhoneRegionPolicy
        }

        return policy
    }

    func configure() {
        client.configure(
            defaults: RemoteConfigDefaults.values,
            minimumFetchInterval: RemoteConfigFetchPolicy.minimumFetchInterval
        )
    }

    func fetchAndActivate() async {
        guard startFetch() else { return }

        defer { finishFetch() }

        do {
            try await client.fetchAndActivate()
        } catch is CancellationError {
            return
        } catch {
            log.error("Remote Config fetch and activation failed.")
        }
    }
}

// MARK: - Private Methods
private extension FirebaseRemoteConfigService {
    func startFetch() -> Bool {
        fetchLock.lock()
        defer { fetchLock.unlock() }

        guard !isFetchInProgress else { return false }

        isFetchInProgress = true
        return true
    }

    func finishFetch() {
        fetchLock.lock()
        defer { fetchLock.unlock() }

        isFetchInProgress = false
    }
}

// MARK: - FirebaseRemoteConfigClient
private final class FirebaseRemoteConfigClient: RemoteConfigClient {
    // MARK: - Private Properties
    private var remoteConfig: RemoteConfig?

    // MARK: - RemoteConfigClient
    func configure(
        defaults: [String: NSObject],
        minimumFetchInterval: TimeInterval
    ) {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings: RemoteConfigSettings = .init()
        settings.minimumFetchInterval = minimumFetchInterval

        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaults)
        self.remoteConfig = remoteConfig
    }

    func fetchAndActivate() async throws {
        guard let remoteConfig else {
            throw RemoteConfigClientError.notConfigured
        }

        _ = try await remoteConfig.fetchAndActivate()
    }

    func stringValue(for key: String) -> String {
        remoteConfig?.configValue(forKey: key).stringValue ?? ""
    }
}

// MARK: - RemoteConfigClientError
private enum RemoteConfigClientError: Error {
    case notConfigured
}
