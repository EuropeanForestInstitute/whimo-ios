//
//  TokenRegistryServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 15.07.2025.
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
import StorageKit
import Networking
import RestClient
import Alamofire
import Utility

final class TokenRegistryServiceImpl: TokenRegistryService {
    // MARK: - Dependencies
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>
    private let restClient: RestClient

    // MARK: - Private Properties
    private var deviceToken: String?
    private var fcmToken: String?
    private var isUpdating = false
    private var request: DataRequest?
    private let queue: DispatchQueue = .init(label: "com.tokenRegistryServiceImpl.queue", attributes: .concurrent)

    // MARK: - Init
    init(
        userDefaultsStore: AnyStorage<UserDefaultsStore>,
        restClient: RestClient
    ) {
        self.userDefaultsStore = userDefaultsStore
        self.restClient = restClient

        restoreTokens()
    }

    // MARK: - TokenRegistryService
    func registerTokens() {
        refreshTokensIfNeeded()
    }

    func updateDeviceToken(_ token: String) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }

            userDefaultsStore.set(token, key: .apnsToken)
            self.deviceToken = userDefaultsStore.get(.apnsToken)
            refreshTokensIfNeeded()
        }
    }

    func updateFCMToken(_ token: String?) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }

            self.fcmToken = token
            userDefaultsStore.set(token, key: .fcmToken)
            refreshTokensIfNeeded()
        }
    }
}

// MARK: - Private Methods
private extension TokenRegistryServiceImpl {
    func restoreTokens() {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }

            self.deviceToken = userDefaultsStore.get(.apnsToken)
            self.fcmToken = userDefaultsStore.get(.fcmToken)
        }
    }

    func refreshTokensIfNeeded() {
        guard
            let isLoggedIn: Bool = userDefaultsStore.get(.isLoggedIn),
            isLoggedIn
        else {
            log.debug("No user logged in.👀 Try to register device tokens after login.👉")
            return
        }

        guard let deviceToken = deviceToken else {
            log.error("Cannot refresh tokens. Push notification permissions not granted.")
            return
        }

        guard let _ = fcmToken else { // swiftlint:disable:this unused_optional_binding
            log.error("Cannot refresh tokens. FcmToken is nil.")
            return
        }

        cancelUpdateRequest()
        isUpdating = true
        defer { self.isUpdating = false }

        do {
            try makeRequest(apnsToken: deviceToken)
        } catch {
            log.error("\(error.localizedDescription)")
        }
    }

    func makeRequest(apnsToken: String) throws {
        let requestModel: RequestModels.AddDevice = .init(registrationId: apnsToken)
        do {
            self.request = try restClient.tryRequest(RequestRouter.UserAgent.addDevice(requestModel))
            Task { [weak self] in
                defer { self?.request = nil }
                let response = await self?.request?.asyncResponseData()

                guard let response = response else { return }

                switch response.result {
                    case .success:
                        guard
                            let responseType = response.response?.status?.responseType
                        else {
                            throw URLError(.cannotParseResponse)
                        }

                        switch responseType {
                            case .success:
                                return
                            default:
                                throw URLError(.badServerResponse)
                        }
                    case .failure(let failure):
                        throw failure
                }
            }
        } catch {
            throw error
        }
    }

    func cancelUpdateRequest() {
        if let request {
            log.debug("Canceling refresh communication tokens request.\n\(request.convertible)")
        }

        request?.cancel()
        request = nil
        isUpdating = false
    }
}
