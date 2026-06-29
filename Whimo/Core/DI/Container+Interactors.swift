//
//  Container+Interactors.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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

import FactoryKit

extension AppContainer {
    // MARK: - Auth
    var authInteractor: Factory<AuthInteractor> {
        self {
            AuthInteractorImpl(
                appState: self.appState.resolve(),
                authRepository: self.authRepository.resolve(),
                appleAuthService: self.appleAuthService.resolve(),
                googleAuthService: self.googleAuthService.resolve(),
                profileRepository: self.profileCachingRepository.resolve(),
                userDefaultsStore: self.userDefaultsStore.resolve()
            )
        }
    }

    // MARK: - Profile
    var profileInteractor: Factory<ProfileInteractor> {
        self {
            ProfileInteractorImpl(
                appState: self.appState.resolve(),
                profileCachingRepository: self.profileCachingRepository.resolve(),
                profileLocalRepository: self.profileLocalRepository.resolve()
            )
        }
    }

    // MARK: - Commodity
    var commodityInteractor: Factory<CommodityInteractor> {
        self {
            CommodityInteractorImpl(
                appState: self.appState.resolve(),
                commodityRepository: self.commodityCachingRepository.resolve(),
            )
        }
    }

    var convertCommodityInteractor: Factory<ConvertCommodityInteractor> {
        self {
            ConvertCommodityInteractorImpl(
                commodityConversionRemoteRepository: self.commodityConversionRemoteRepository.resolve()
            )
        }
        .onPreview {
            ConvertCommodityInteractorMock(commodityConversionRemoteRepository: self.commodityConversionRemoteRepository.resolve())
        }
    }

    // MARK: - Balance
    var balanceInteractor: Factory<BalanceInteractor> {
        self {
            BalanceInteractorImpl(
                appState: self.appState.resolve(),
                balanceLocalRepository: self.balanceLocalRepository.resolve(),
                commodityCachingRepositoryImpl: self.commodityCachingRepository.resolve()
            )
        }
    }

    // MARK: - Transactions
    var transactionsInteractor: Factory<TransactionsInteractor> {
        self {
            TransactionsInteractorImpl(
                appState: self.appState.resolve(),
                transactionsRemoteRepository: self.transactionsRemoteRepository.resolve(),
                transactionsCachingRepository: self.transactionsCachingRepository.resolve(),
                transactionsLocalRepository: self.transactionsLocalRepository.resolve()
            )
        }
    }

    // MARK: - Notifications
    var notificationsInteractor: Factory<NotificationsInteractor> {
        self {
            NotificationsInteractorImpl(
                appState: self.appState.resolve(),
                notificationsCachingRepository: self.notificationsCachingRepository.resolve(),
                notificationsLocalRepository: self.notificationsLocalRepository.resolve()
            )
        }
    }

    // MARK: - NotificationsSettings
    var notificationsSettingsInteractor: Factory<NotificationsSettingsInteractor> {
        self {
            NotificationsSettingsInteractorImpl(
                appState: self.appState.resolve(),
                notificationsSettingsRepository: self.notificationsSettingsCachingRepository.resolve()
            )
        }
    }

    // MARK: - DataCleaner
    var dataCleanerInteractor: Factory<DataCleanerInteractor> {
        self {
            DataCleanerInteractorImpl(
                appState: self.appState.resolve(),
                database: self.database.resolve(),
                authRepository: self.authRepository.resolve(),
                profileCachingRepository: self.profileCachingRepository.resolve(),
                keychainStore: self.keychainStore.resolve(),
                userDefaultsStore: self.userDefaultsStore.resolve()
            )
        }
    }

    // MARK: - DataFetcher
    var dataFetcherInteractor: Factory<DataFetcherInteractor> {
        self {
            DataFetcherInteractorImpl(
                profileInteractor: self.profileInteractor.resolve(),
                notificationsSettingsInteractor: self.notificationsSettingsInteractor.resolve(),
                transactionsInteractor: self.transactionsInteractor.resolve(),
                balanceInteractor: self.balanceInteractor.resolve(),
                notificationsInteractor: self.notificationsInteractor.resolve(),
                connectivity: self.connectivity.resolve()
            )
        }
    }

    // MARK: - OfflineTransactionsSync
    var offlineTransactionsSyncInteractor: Factory<OfflineTransactionsSyncInteractor> {
        self {
            OfflineTransactionsSyncInteractorImpl(
                appState: self.appState.resolve(),
                transactionsLocalRepository: self.transactionsLocalRepository.resolve(),
                transactionsOfflineMapper: self.transactionsOfflineMapper.resolve(),
                transactionsTarget: self.transactionsTarget.resolve(),
                transactionsMapper: self.transactionsMapper.resolve()
            )
        }
    }
}
