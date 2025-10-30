//
//  StateRegistryServiceImpl.swift
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
import Networking

final class StateRegistryServiceImpl: StateRegistryService {
    // MARK: - Dependencies
    private let profileService: any ProfileService
    private let notificationsSettingsService: any NotificationsSettingsService
    private let transactionService: any TransactionsService
    private let balanceService: any BalanceService
    private let notificationsService: any NotificationsService

    private let connectivity: any Connectivity
    private let profileCacheService: any ProfileCacheService
    private let transactionsCacheService: any TransactionsCacheService
    private let balanceCacheService: any BalanceCacheService
    private let notificationsCacheService: any NotificationsCacheService

    // MARK: - Init
    init(
        profileService: any ProfileService,
        notificationsSettingsService: any NotificationsSettingsService,
        transactionService: any TransactionsService,
        balanceService: any BalanceService,
        notificationsService: any NotificationsService,
        connectivity: any Connectivity,
        profileCacheService: any ProfileCacheService,
        transactionsCacheService: any TransactionsCacheService,
        balanceCacheService: any BalanceCacheService,
        notificationsCacheService: any NotificationsCacheService
    ) {
        self.profileService = profileService
        self.notificationsSettingsService = notificationsSettingsService
        self.transactionService = transactionService
        self.balanceService = balanceService
        self.notificationsService = notificationsService

        self.connectivity = connectivity
        self.profileCacheService = profileCacheService
        self.transactionsCacheService = transactionsCacheService
        self.balanceCacheService = balanceCacheService
        self.notificationsCacheService = notificationsCacheService
    }

    // MARK: - StateRegistryService
    func fetchRemoteData() async {
        async let fetchProfile: Void = profileService.fetchProfile()
        async let fetchSettings: Void = notificationsSettingsService.fetchSettings()
        async let fetchTransactions: Void = transactionService.fetchTransactions(searchData: .empty, refresh: true)
        async let fetchBalance: Void = balanceService.fetchCommodityGroupsBalance()
        async let fetchNotifications: Void = connectivity.isReachableFlag
        ? notificationsService.fetchNotifications(notificationTypes: [], refresh: false)
        : ()

        _ = (
            try? await fetchProfile,
            try? await fetchSettings,
            try? await fetchTransactions,
            try? await fetchBalance,
            try? await fetchNotifications
        )
    }

    func loadCacheData() async {
        async let fetchProfile: Void = profileCacheService.fetchProfile()
        async let fetchTransactions: Void = transactionsCacheService.fetchTransactions()
        async let fetchBalance: Void = balanceCacheService.fetchCommodityGroupsBalance()
        async let fetchNotifications: Void = connectivity.isReachableFlag ? notificationsCacheService.fetchNotifications() : ()

        _ = (
            try? await fetchProfile,
            try? await fetchTransactions,
            try? await fetchBalance,
            try? await fetchNotifications
        )
    }
}
