//
//  Container+Repositories.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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
    var authRepository: Factory<AuthRepository> {
        self {
            AuthRepositoryImpl(
                authTarget: self.authTarget.resolve(),
                tokenManager: self.tokenManager.resolve(),
                userDefaultsStore: self.userDefaultsStore.resolve()
            )
        }
    }

    // MARK: - Profile
    var profileLocalRepository: Factory<ProfileLocalRepository> {
        self {
            ProfileLocalRepositoryImpl(
                keychainStore: self.keychainStore.resolve(),
                userMapper: self.userMapper.resolve()
            )
        }
    }

    var profileRemoteRepository: Factory<ProfileRemoteRepository> {
        self {
            ProfileRemoteRepositoryImpl(
                usersTarget: self.usersTarget.resolve(),
                userMapper: self.userMapper.resolve()
            )
        }
    }

    var profileCachingRepository: Factory<ProfileCachingRepository> {
        self {
            ProfileCachingRepositoryImpl(
                localRepo: self.profileLocalRepository.resolve(),
                remoteRepo: self.profileRemoteRepository.resolve()
            )
        }
    }

    // MARK: - Commodity
    var commodityLocalRelository: Factory<CommodityLocalRepository> {
        self {
            CommodityLocalRepositoryImpl(
                database: self.database.resolve(),
                commoditiesGroupsMapper: self.commoditiesGroupsMapper.resolve()
            )
        }
    }

    var commodityRemoteRepository: Factory<CommodityRemoteRepository> {
        self {
            CommodityRemoteRepositoryImpl(
                commoditiesTarget: self.commoditiesTarget.resolve(),
                commoditiesGroupsMapper: self.commoditiesGroupsMapper.resolve()
            )
        }
    }

    var commodityCachingRepository: Factory<CommodityCachingRepository> {
        self {
            CommodityCachingRepositoryImpl(
                localRepo: self.commodityLocalRelository.resolve(),
                remoteRepo: self.commodityRemoteRepository.resolve()
            )
        }
    }

    // MARK: - Commodity Conversion
    var commodityConversionRemoteRepository: Factory<CommodityConversionRemoteRepository> {
        self {
            CommodityConversionRemoteRepositoryImpl(
                commodityConversionTarget: self.commodityConversionTarget.resolve(),
                commodityConversionMapper: self.commodityConversionMapper.resolve()
            )
        }
        .onPreview {
            CommodityConversionRemoteRepositoryMock(
                commodityConversionTarget: self.commodityConversionTarget.resolve(),
                commodityConversionMapper: self.commodityConversionMapper.resolve()
            )
        }
    }

    // MARK: - Balance
    var balanceLocalRepository: Factory<BalanceLocalRepository> {
        self {
            BalanceLocalRepositoryImpl(
                database: self.database.resolve(),
                commoditiesGroupsMapper: self.commoditiesGroupsMapper.resolve()
            )
        }
    }

    // MARK: - Transactions
    var transactionsLocalRepository: Factory<TransactionsLocalRepository> {
        self {
            TransactionsLocalRepositoryImpl(
                database: self.database.resolve(),
                commoditiesGroupsMapper: self.commoditiesGroupsMapper.resolve(),
                transactionsMapper: self.transactionsMapper.resolve(),
                transactionsOfflineMapper: self.transactionsOfflineMapper.resolve(),
                userMapper: self.userMapper.resolve(),
                userOfflineMapper: self.userOfflineMapper.resolve(),
                keychainStore: self.keychainStore.resolve()
            )
        }
    }

    var transactionsRemoteRepository: Factory<TransactionsRemoteRepository> {
        self {
            TransactionsRemoteRepositoryImpl(
                transactionsTarget: self.transactionsTarget.resolve(),
                transactionsMapper: self.transactionsMapper.resolve(),
                supplierTransactionMapper: self.supplierTransactionMapper.resolve()
            )
        }
    }

    var transactionsCachingRepository: Factory<TransactionsCachingRepository> {
        self {
            TransactionsCachingRepositoryImpl(
                localRepo: self.transactionsLocalRepository.resolve(),
                remoteRepo: self.transactionsRemoteRepository.resolve()
            )
        }
    }

    // MARK: - Transaction Traceability
    var trxTraceabilityLocalRepository: Factory<TrxTraceabilityLocalRepository> {
        self {
            TrxTraceabilityLocalRepositoryImpl(
                database: self.database.resolve(),
                transactionTraceabilityMapper: self.transactionTraceabilityMapper.resolve()
            )
        }
    }

    var trxTraceabilityRemoteRepository: Factory<TrxTraceabilityRemoteRepository> {
        self {
            TrxTraceabilityRemoteRepositoryImpl(
                transactionsTarget: self.transactionsTarget.resolve(),
                transactionTraceabilityMapper: self.transactionTraceabilityMapper.resolve()
            )
        }
    }

    var trxTraceabilityCachingRepository: Factory<TrxTraceabilityCachingRepository> {
        self {
            TrxTraceabilityCachingRepositoryImpl(
                localRepo: self.trxTraceabilityLocalRepository.resolve(),
                remoteRepo: self.trxTraceabilityRemoteRepository.resolve()
            )
        }
    }

    // MARK: - Notifications
    var notificationsLocalRepository: Factory<NotificationsLocalRepository> {
        self {
            NotificationsLocalRepositoryImpl(
                database: self.database.resolve(),
                notificationsMapper: self.notificationsMapper.resolve()
            )
        }
    }

    var notificationsRemoteRepository: Factory<NotificationsRemoteRepository> {
        self {
            NotificationsRemoteRepositoryImpl(
                notificationsTarget: self.notificationsTarget.resolve(),
                notificationsMapper: self.notificationsMapper.resolve()
            )
        }
    }

    var notificationsCachingRepository: Factory<NotificationsCachingRepository> {
        self {
            NotificationsCachingRepositoryImpl(
                transactionLocalRepo: self.transactionsLocalRepository.resolve(),
                localRepo: self.notificationsLocalRepository.resolve(),
                remoteRepo: self.notificationsRemoteRepository.resolve()
            )
        }
    }

    // MARK: - Notifications Settings
    var notificationsSettingsLocalRepository: Factory<NotificationsSettingsLocalRepository> {
        self {
            NotificationsSettingsLocalRepositoryImpl(
                database: self.database.resolve(),
                notificationsSettingsMapper: self.notificationsSettingsMapper.resolve()
            )
        }
    }

    var notificationsSettingsRemoteRepository: Factory<NotificationsSettingsRemoteRepository> {
        self {
            NotificationsSettingsRemoteRepositoryImpl(
                notificationsSettingsTarget: self.notificationsSettingsTarget.resolve(),
                notificationsSettingsMapper: self.notificationsSettingsMapper.resolve()
            )
        }
    }

    var notificationsSettingsCachingRepository: Factory<NotificationsSettingsCachingRepository> {
        self {
            NotificationsSettingsCachingRepositoryImpl(
                localRepo: self.notificationsSettingsLocalRepository.resolve(),
                remoteRepo: self.notificationsSettingsRemoteRepository.resolve()
            )
        }
    }
}
