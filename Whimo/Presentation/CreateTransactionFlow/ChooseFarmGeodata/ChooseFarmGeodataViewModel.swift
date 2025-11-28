//
//  ChooseFarmGeodataViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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

import SwiftUI
import Utility
import Resources
import class CommonUI.ToastManager

private typealias Module = ChooseFarmGeodataModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        var list: IdentifiedArrayOf<Row> {
            switch transactionType {
                case .producer(let seller):
                    switch seller {
                        case .farmer(isCurrentlyOnFarm: let isCurrentlyOnFarm):
                            if isCurrentlyOnFarm {
                                return .init(uniqueElements: [.qrCode, .currentLocation, .addLocation])
                            } else {
                                return .init(uniqueElements: [.qrCode, .addLocation])
                            }
                        case .cooperative:
                            return .init(uniqueElements: [])
                    }
                case .downstream:
                    return .init(uniqueElements: [])
            }
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private let transactionType: TransactionType

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.locationService) private var locationService
        @Inject(\.hapticsEngineService) private var hapticsEngineService

        // MARK: - Init
        init() {
            @Inject(\.appState) var appState
            guard
                let transactionType = appState.createTransaction.value.transactionType
            else { preconditionFailure("Unsupported transaction. Cannot initialize module without `transactionType` property.") }

            self.transactionType = transactionType

            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func pickCurrentCoordinates() {
            typealias Localization = AppLocale.ChooseFarmGeodata.Toast.LocationPermission
            Task { [weak self] in
                guard let self else { return }

                let location = await self.locationService.getUserLocation()

                self.hapticsEngineService.produceButtonImpact()

                guard let location else {
                    let message = Localization.message
                    log.error(message)
                    let button: ToastManager.ToastButton = .init(
                        title: Localization.Button.openSettings,
                        color: AppColors.Expanded.expandedSuccess.colorSwiftUI,
                        action: self.appState.navigation.value.openSystemSettings
                    )
                    await self.appState.showError(message: message, button: button)
                    return
                }

                self.appState.createTransaction[\.farmLocation] = .gps(coordinates: location.coordinate)
                self.appState.navigation[\.path].removeLast()
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() { }

    func startup() { }
}
