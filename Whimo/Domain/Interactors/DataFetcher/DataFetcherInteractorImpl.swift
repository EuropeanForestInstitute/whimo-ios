//
//  AppInitializationInteractorImpl.swift
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
import RestClient

final class DataFetcherInteractorImpl: DataFetcherInteractor {
    // MARK: - Dependencies
    private let profileInteractor: ProfileInteractor
    private let notificationsSettingsInteractor: NotificationsSettingsInteractor
    private let transactionsInteractor: TransactionsInteractor
    private let balanceInteractor: BalanceInteractor
    private let notificationsInteractor: NotificationsInteractor

    private let connectivity: any Connectivity

    // MARK: - Init
    init(
        profileInteractor: ProfileInteractor,
        notificationsSettingsInteractor: NotificationsSettingsInteractor,
        transactionsInteractor: TransactionsInteractor,
        balanceInteractor: BalanceInteractor,
        notificationsInteractor: NotificationsInteractor,
        connectivity: any Connectivity
    ) {
        self.profileInteractor = profileInteractor
        self.notificationsSettingsInteractor = notificationsSettingsInteractor
        self.transactionsInteractor = transactionsInteractor
        self.balanceInteractor = balanceInteractor
        self.notificationsInteractor = notificationsInteractor
        self.connectivity = connectivity
    }

    // MARK: - DataFetcherInteractor

    /// Fetches all remote data (profile, settings, transactions, balance, notifications)
    func fetchRemoteData() async {
        async let fetchProfile: Void = profileInteractor.fetchProfile()
        async let fetchSettings: Void = notificationsSettingsInteractor.fetchSettings()
        async let fetchTransactions: Void = transactionsInteractor.fetchTransactions(searchData: RequestModels.TransactionsList.SearchData.empty, refresh: true)
        async let fetchBalance: Void = balanceInteractor.fetchCommodityGroupsBalance()
        async let fetchNotifications: Void = connectivity.isReachableFlag
        ? notificationsInteractor.fetchNotifications(notificationTypes: [], refresh: false)
        : ()

        _ = (
            try? await fetchProfile,
            try? await fetchSettings,
            try? await fetchTransactions,
            try? await fetchBalance,
            try? await fetchNotifications
        )
    }

    /// Loads all data from local cache only (offline mode)
    func loadCacheData() async {
        async let fetchProfile: Void = profileInteractor.fetchProfileFromCache()
        async let fetchTransactions: Void = transactionsInteractor.fetchTransactionsFromCache()
        async let fetchBalance: Void = balanceInteractor.fetchCommodityGroupsBalanceFromCache()
        async let fetchNotifications: Void = connectivity.isReachableFlag ? notificationsInteractor.fetchNotificationsFromCache() : ()

        _ = (
            try? await fetchProfile,
            try? await fetchTransactions,
            try? await fetchBalance,
            try? await fetchNotifications
        )
    }
}
