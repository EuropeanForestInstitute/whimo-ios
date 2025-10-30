//
//  StartupService.swift
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
import Utility

actor StartupService {
    // MARK: - Dependencies
    @Inject(\.tokenManager) private var tokenManager
    @Inject(\.keychainStore) private var keychainStore
    @Inject(\.userDefaultsStore) private var userDefaultsStore

    // MARK: - Public Methods
    func initNetworking() {
        let accessToken: String? = keychainStore.get(.accessToken)
        let refreshToken: String? = keychainStore.get(.refreshToken)

        let fcmToken: String? = userDefaultsStore.get(.fcmToken)
        log.debug("[defaults] fcmToken: \(fcmToken ?? "-")")

        log.debug("accessToken: \(accessToken ?? "-")")
        log.debug("refreshToken: \(refreshToken ?? "-")")

        guard
            let accessToken,
            let refreshToken
        else {
            log.error("JWT tokens not found. Networking cannot be initialized.")
            return
        }

        tokenManager.updateToken(.init(access: accessToken, refresh: refreshToken))
    }
}
