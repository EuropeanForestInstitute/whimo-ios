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

    var transactionDocumentsService: Factory<TransactionDocumentsService> {
        self {
            TransactionDocumentsServiceImpl(
                transactionsTarget: self.transactionsTarget.resolve(),
                fileStorage: self.fileStorage.resolve()
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

    var emailClientService: Factory<EmailClientService> {
        self { EmailClientServiceImpl() }
    }

}
