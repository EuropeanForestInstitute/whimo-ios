//
//  Container+Services.swift
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
import class CommonUI.ToastManager
import class CommonUI.AlertManager

extension AppContainer {
    var toastManager: Factory<ToastManager> {
        self { .init() }
    }

    var alertManager: Factory<AlertManager> {
        self { .init() }
    }

    var hapticsEngineService: Factory<HapticsEngineServiceProtocol> {
        self { HapticsEngineService() }
    }

    var userAgentService: Factory<UserAgentServiceProtocol> {
        self { UserAgentService(userDefaultsStore: self.userDefaultsStore.resolve()) }
    }

    var fileStorage: Factory<FileStorageServiceProtocol> {
        self { FileStorageService() }
    }

    var permissionsService: Factory<PermissionsServiceProtocol> {
        self { PermissionsService(notificationCenter: .current()) }
    }

    var locationService: Factory<LocationServiceProtocol> {
        self {
            LocationService(
                userDefaultsStore: self.userDefaultsStore.resolve(),
                permissionsService: self.permissionsService.resolve()
            )
        }
    }

    var authService: Factory<AuthService> {
        self {
            AuthServiceImpl(
                appState: self.appState.resolve(),
                authRepository: self.authRepository.resolve(),
                appleAuthService: self.appleAuthService.resolve(),
                googleAuthService: self.googleAuthService.resolve(),
                profileRepository: self.profileCachingRepository.resolve(),
                userDefaultsStore: self.userDefaultsStore.resolve()
            )
        }
    }

    var commoditiesService: Factory<CommodityService> {
        self {
            CommodityServiceImpl(
                appState: self.appState.resolve(),
                commodityRepository: self.commodityCachingRepository.resolve(),
                balanceRepository: self.balanceCachingRepository.resolve()
            )
        }
    }

    var transactionService: Factory<TransactionsService> {
        self {
            TransactionsServiceImpl(
                appState: self.appState.resolve(),
                transactionsRemoteRepository: self.transactionsRemoteRepository.resolve(),
                transactionsCachingRepository: self.transactionsCachingRepository.resolve()
            )
        }
    }

    var balanceService: Factory<BalanceService> {
        self {
            BalanceServiceImpl(
                appState: self.appState.resolve(),
                balanceCachingRepository: self.balanceCachingRepository.resolve()
            )
        }
    }

    var balanceCacheService: Factory<BalanceCacheService> {
        self {
            BalanceCacheServiceImpl(
                appState: self.appState.resolve(),
                localRepo: self.balanceLocalRepository.resolve()
            )
        }
    }

    var transactionsCacheService: Factory<TransactionsCacheService> {
        self {
            TransactionsCacheServiceImpl(
                appState: self.appState.resolve(),
                localRepo: self.transactionsLocalRepository.resolve()
            )
        }
    }

    var transactionDocumentsService: Factory<TransactionDocumentsService> {
        self {
            TransactionDocumentsServiceImpl(
                transactionsTarget: self.transactionsTarget.resolve(),
                geojsonMapper: self.geojsonMapper.resolve(),
                fileStorage: self.fileStorage.resolve()
            )
        }
    }

    var offlineTransactionsSyncService: Factory<OfflineTransactionsSyncService> {
        self {
            OfflineTransactionsSyncServiceImpl(
                appState: self.appState.resolve(),
                transactionsLocalRepository: self.transactionsLocalRepository.resolve(),
                transactionsOfflineMapper: self.transactionsOfflineMapper.resolve(),
                transactionsTarget: self.transactionsTarget.resolve(),
                transactionsMapper: self.transactionsMapper.resolve()
            )
        }
    }

    var dataCleanerService: Factory<DataCleanerService> {
        self {
            DataCleanerServiceImpl(
                appState: self.appState.resolve(),
                database: self.database.resolve(),
                authRepository: self.authRepository.resolve(),
                profileCachingRepository: self.profileCachingRepository.resolve(),
                keychainStore: self.keychainStore.resolve(),
                userDefaultsStore: self.userDefaultsStore.resolve()
            )
        }
    }

    var notificationsService: Factory<NotificationsService> {
        self {
            NotificationsServiceImpl(
                appState: self.appState.resolve(),
                notificationsCachingRepository: self.notificationsCachingRepository.resolve()
            )
        }
    }

    var notificationsCacheService: Factory<NotificationsCacheService> {
        self {
            NotificationsCacheServiceImpl(
                appState: self.appState.resolve(),
                localRepo: self.notificationsLocalRepository.resolve()
            )
        }
    }

    var notificationsSettingsService: Factory<NotificationsSettingsService> {
        self {
            NotificationsSettingsServiceImpl(
                appState: self.appState.resolve(),
                notificationsSettingsRepository: self.notificationsSettingsCachingRepository.resolve()
            )
        }
    }

    var profileService: Factory<ProfileService> {
        self {
            ProfileServiceImpl(
                appState: self.appState.resolve(),
                profileCachingRepository: self.profileCachingRepository.resolve()
            )
        }
    }

    var profileCacheService: Factory<ProfileCacheService> {
        self {
            ProfileCacheServiceImpl(
                appState: self.appState.resolve(),
                localRepo: self.profileLocalRepository.resolve()
            )
        }
    }

    var userNotificationsService: Factory<UserNotificationsServiceProtocol> {
        self { UserNotificationsService() }
    }

    var firebaseService: Factory<FirebaseService> {
        self { FirebaseServiceImpl() }
    }

    var appleAuthService: Factory<AppleAuthService> {
        self {
            AppleAuthServiceImpl()
        }
    }

    var googleAuthService: Factory<GoogleAuthService> {
        self {
            GoogleAuthServiceImpl()
        }
    }

    var qrCodeDataService: Factory<QRCodeDataService> {
        self {
            QRCodeDataServiceImpl(fileStorage: self.fileStorage.resolve())
        }
    }

    var tokenRegistryService: Factory<TokenRegistryService> {
        self {
            TokenRegistryServiceImpl(
                userDefaultsStore: self.userDefaultsStore.resolve(),
                restClient: self.restClient.resolve()
            )
        }
    }

    var stateRegistryService: Factory<StateRegistryService> {
        self {
            StateRegistryServiceImpl(
                profileService: self.profileService.resolve(),
                notificationsSettingsService: self.notificationsSettingsService.resolve(),
                transactionService: self.transactionService.resolve(),
                balanceService: self.balanceService.resolve(),
                notificationsService: self.notificationsService.resolve(),
                connectivity: self.connectivity.resolve(),
                profileCacheService: self.profileCacheService.resolve(),
                transactionsCacheService: self.transactionsCacheService.resolve(),
                balanceCacheService: self.balanceCacheService.resolve(),
                notificationsCacheService: self.notificationsCacheService.resolve()
            )
        }
    }
}
