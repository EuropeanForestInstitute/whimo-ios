//
//  CreateTransactionFormViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import CoreLocation
import Utility
import class CommonUI.AlertManager
import enum Resources.LocalizeKeys
import Extensions

private typealias Module = CreateTransactionFormModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var farmLocation: FarmLocation?
        @Published private(set) var commodityType: CommodityGroupModel.Commodity = .initialState
        @Published private(set) var volumeAmount: String = ""
        @Published private(set) var transactionType: TransactionType

        var list: IdentifiedArrayOf<Row> {
            switch transactionType {
                case .producer(let seller):
                    switch seller {
                        case .cooperative:
                            return .init(uniqueElements: [.geodata, .commodity, .volume, .inviteSupplier])
                        default:
                            return .init(uniqueElements: [.geodata, .commodity, .volume])
                    }
                case .downstream(let action, _):
                    switch action {
                        case .buy:
                            return .init(uniqueElements: [.commodity, .volume, .supplier])
                        case .sell:
                            return .init(uniqueElements: [.commodity, .volume, .buyer])
                    }
            }
        }
        var isSaveButtonEnabled: Bool {
            let commoditySuccess = commodityType != .initialState
            && !volumeAmount.isEmpty

            switch transactionType {
                case .producer:
                    return commoditySuccess
                case .downstream(_, let recipient):
                    return recipient.recipientContact != nil && commoditySuccess
            }
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionsTarget) private var transactionsTarget
        @Inject(\.transactionsInteractor) private var transactionsInteractor
        @Inject(\.fileStorage) private var fileStorage
        @Inject(\.locationService) private var locationService

        // MARK: - Init
        init(transactionType: TransactionType) {
            self.transactionType = transactionType

            setupBinding()
            initTransaction()
        }

        deinit {
            appState.createTransaction.dispatch { state in
                state.clear()
            }
        }

        // MARK: - ViewModelProtocol
        func saveTransaction() {
            alertManager.show(feature: AlertManager.AlertModel.Features.SaveTransaction.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .reviewInfo:
                        return nil
                    case .save:
                        return self.didTapSave
                }
            }
        }

        func saveTransactionWithNoLocation() {
            alertManager.show(feature: AlertManager.AlertModel.Features.SaveTransactionWithNoLocation.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .save:
                        return self.didTapSave
                    case .addFarmGeodata:
                        return nil
                }
            }
        }

        func didTapChooseFarmGeodataScreen() {
            let seller: TransactionType.Seller
            switch transactionType {
                case .producer(let transactionSeller):
                    seller = transactionSeller
                case .downstream:
                    return
            }

            switch seller {
                case .farmer:
                    appState.navigation[\.path].append(.push(.chooseFarmGeodata))
                case .cooperative:
                    appState.navigation[\.path].append(.push(.uploadFile(mode: .filePicker)))
            }
        }

        func didTapOpenCommodityVolumeScreen() {
            let state = appState.createTransaction.value

            let screen: Screen = .commodityVolume(
                volumeAmount: state.volumeAmount,
                commodityType: state.commodityType,
                transactionType: transactionType
            )
            appState.navigation[\.path].append(.push(screen))
        }

        func isFarmLocationExists() -> Bool {
            guard
                let farmLocation
//                let url = farmLocation.selectedFile?.url,
//                let resultData: Data = fileStorage.contents(of: url, securityScoped: true),
//                let string: String = .init(data: resultData, encoding: .utf8)
            else { return false }

//            return !string.isEmpty
            return true
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.createTransaction.state
            .map(\.farmLocation)
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.farmLocation)
            .store(in: cancellable)
        appState.createTransaction.state
            .map(\.commodityType)
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.commodityType)
            .store(in: cancellable)
        appState.createTransaction.state
            .map(\.volumeAmount)
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.volumeAmount)
            .store(in: cancellable)
        appState.createTransaction.state
            .map(\.transactionType)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .animatedAssign(on: self, to: \.transactionType)
            .store(in: cancellable)
    }

    // MARK: - Common
    func initTransaction() {
        appState.createTransaction[\.transactionType] = transactionType
    }

    func didTapSave() {
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            switch self.transactionType {
                case .producer(let seller):
                    var inviteRecipient: TransactionType.Recipient?
                    switch seller {
                        case .farmer:
                            break
                        case .cooperative(let recipient):
                            inviteRecipient = recipient
                    }

                    let farmLocation = self.farmLocation
                    let success = await self.createProducerTransactionRequest(
                        farmLocation: farmLocation,
                        commodityType: self.commodityType,
                        volume: self.volumeAmount,
                        transactionType: transactionType,
                        inviteRecipient: inviteRecipient
                    )

                    guard success else { return }

                    popToRoot()
                case .downstream(let action, let recipient):
                    let success = await self.createDownstreamTransactionRequest(
                        farmLocation: farmLocation,
                        commodityType: self.commodityType,
                        volume: self.volumeAmount,
                        action: action,
                        recipient: recipient
                    )

                    guard success else { return }

                    popToRoot()
            }
        }
    }

    func createProducerTransactionRequest(
        farmLocation: FarmLocation?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        transactionType: TransactionType,
        inviteRecipient: TransactionType.Recipient?
    ) async -> Bool {
        do {
            var isBuyingFromFarmer: Bool = false
            switch transactionType {
                case .producer(let transactionSeller):
                    isBuyingFromFarmer = transactionSeller.isFarmer
                case .downstream:
                    break
            }

            let location = await locationService.getUserLocation()
            try await transactionsInteractor.createProducerTransaction(
                farmLocation: farmLocation,
                commodityType: commodityType,
                volume: volume,
                isBuyingFromFarmer: isBuyingFromFarmer,
                transactionCoordinates: location?.coordinate,
                inviteRecipient: inviteRecipient
            )

            return true
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func createDownstreamTransactionRequest(
        farmLocation: FarmLocation?,
        commodityType: CommodityGroupModel.Commodity,
        volume: String,
        action: TransactionModel.Action,
        recipient: TransactionType.Recipient
    ) async -> Bool {
        do {
            let location = await locationService.getUserLocation()
            try await transactionsInteractor.createDownstreamTransaction(
                farmLocation: farmLocation,
                transactionCoordinates: location?.coordinate,
                commodityType: commodityType,
                volume: volume,
                action: action,
                recipient: recipient
            )

            return true
        } catch {
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }

    func popToRoot() {
        appState.system.dispatch { state in
            state.selectedTab = .home
        }
        appState.navigation.dispatch { state in
            let navigationStackLevel = state.path.count
            state.path.removeLast(max(.zero, navigationStackLevel - 1))
        }
    }
}
