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
import Resources
import Extensions

private typealias Module = CreateTransactionFormModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var farmLocation: FarmLocation?
        @Published private(set) var commodityType: CommodityGroupModel.Commodity = .initialState
        @Published private(set) var seasonSelection: CreationSeason?
        @Published private(set) var confirmedBalance: ConfirmedSeasonalBalance?
        @Published private(set) var isRefreshingBalance = false

        var volumeBreakdown: SaleVolumeBreakdown? {
            guard case .downstream(.sell, _) = transactionType, let season = volumeSeason,
                  let confirmedBalance, confirmedBalance.commodityId == commodityType.id,
                  confirmedBalance.seasonId == season.id else { return nil }

            return .init(volume: volumeAmount, season: season, balance: confirmedBalance.balance)
        }
        var saleValidation: SeasonalSaleValidation {
            let balance = confirmedBalance.flatMap {
                $0.commodityId == commodityType.id && $0.seasonId == volumeSeason?.id ? $0.balance : nil
            }
            return .init(volume: volumeAmount, season: volumeSeason, balance: balance)
        }

        var saleSummaryMessage: String? {
            guard case .downstream(.sell, _) = transactionType, let season = volumeSeason else { return nil }

            switch saleValidation {
                case .balanceUnavailable:
                    return AppLocale.CreateTransactionForm.VolumeSummary.unavailable
                case .seasonalShortage:
                    return AppLocale.CreationSeason.insufficientBalance(TransactionSeasonPresentation(season: season).title)
                default:
                    return nil
            }
        }
        @Published private(set) var volumeAmount: String = ""
        @Published private(set) var transactionType: TransactionType
        @Published private var producerSeason: CreationSeason?

        var volumeSeason: HarvestSeason? {
            let selection = transactionType.isProducer ? producerSeason : seasonSelection
            guard !volumeAmount.isEmpty,
                  let selection, selection.commodityId == commodityType.id else { return nil }

            return selection.season
        }

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
                case .downstream(let action, let recipient):
                    let seasonValid = seasonSelection?.commodityId == commodityType.id
                    return recipient.recipientContact != nil && commoditySuccess && seasonValid
                        && (action != .sell || saleValidation.permitsSale)
            }
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private var balanceGeneration = UUID()
        private let draftID = UUID()
        private var draftGeneration: BusinessDataContext.Generation?
        private var isSubmitting = false
        private var hasSaved = false

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.businessModeInteractor) private var businessModeInteractor
        @Inject(\.businessDataContext) private var businessDataContext
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionsTarget) private var transactionsTarget
        @Inject(\.transactionsInteractor) private var transactionsInteractor
        @Inject(\.creationSeasonInteractor) private var creationSeasonInteractor
        @Inject(\.fileStorage) private var fileStorage
        @Inject(\.locationService) private var locationService

        // MARK: - Init
        init(transactionType: TransactionType) {
            self.transactionType = transactionType
            draftGeneration = try? businessDataContext.capture()

            initTransaction()
            let draft = appState.createTransaction.value
            commodityType = draft.commodityType
            volumeAmount = draft.volumeAmount
            seasonSelection = draft.seasonSelection
            confirmedBalance = draft.confirmedBalance
            farmLocation = draft.farmLocation
            setupBinding()
        }

        deinit {
            appState.createTransaction.dispatch { state in
                guard state.draftID == draftID else { return }

                state.clear()
            }
        }

        // MARK: - ViewModelProtocol
        @MainActor func refreshProducerSeason() async {
            let draft = appState.createTransaction.value
            guard !Task.isCancelled, draft.draftID == draftID, case .producer = draft.transactionType,
                  draft.commodityType != .initialState else { return }

            if producerSeason?.commodityId != draft.commodityType.id { producerSeason = nil }
            let season: HarvestSeason?
            do {
                let catalogue = try await creationSeasonInteractor.seasons(commodityId: draft.commodityType.id)
                let active = catalogue.values.filter { $0.status == .active && !$0.id.isEmpty }
                season = active.count == 1 ? active.first : nil
            } catch is CancellationError {
                return
            } catch {
                season = nil
            }
            guard !Task.isCancelled, appState.createTransaction.value.draftID == draftID,
                  appState.createTransaction.value.balanceRevision == draft.balanceRevision,
                  appState.createTransaction.value.commodityType.id == draft.commodityType.id,
                  let draftGeneration, (try? draftGeneration.check()) != nil else { return }

            producerSeason = season.map { .init(commodityId: draft.commodityType.id, season: $0) }
        }

        @MainActor func refreshBalance() async {
            guard !Task.isCancelled else { return }

            let generation = UUID()
            balanceGeneration = generation
            isRefreshingBalance = false
            let draft = appState.createTransaction.value
            guard draft.draftID == draftID, case .downstream(.sell, _) = draft.transactionType,
                  let selection = draft.seasonSelection, selection.commodityId == draft.commodityType.id else { return }

            var refreshedSeason = selection.season
            isRefreshingBalance = true
            defer {
                if balanceGeneration == generation { isRefreshingBalance = false }
            }
            do {
                refreshedSeason = try await creationSeasonInteractor.validate(selection, commodityId: selection.commodityId)
                try Task.checkCancellation()
                guard balanceGeneration == generation, appState.createTransaction.value.draftID == draft.draftID,
                      appState.createTransaction.value.balanceRevision == draft.balanceRevision else { return }
                guard refreshedSeason.id == selection.season.id else { throw CreationSeasonError.invalidSelection }

                let balance = try await creationSeasonInteractor.balance(commodityId: selection.commodityId, seasonId: selection.season.id)
                try Task.checkCancellation()
                guard balanceGeneration == generation else { return }
                guard balance.volume.isFinite, balance.volume >= 0 else { throw SeasonalBalanceError.incompleteResponse }

                appState.createTransaction.dispatch { state in
                    guard state.draftID == draft.draftID, state.balanceRevision == draft.balanceRevision else { return }

                    state.seasonSelection = .init(commodityId: selection.commodityId, season: refreshedSeason)
                    state.confirmedBalance = .init(commodityId: selection.commodityId, seasonId: selection.season.id, balance: balance)
                }
            } catch {
                guard !(error is CancellationError), !Task.isCancelled, balanceGeneration == generation else { return }

                appState.createTransaction.dispatch { state in
                    guard state.draftID == draft.draftID, state.balanceRevision == draft.balanceRevision else { return }

                    if case CreationSeasonError.invalidSelection = error {
                        state.confirmedBalance = nil
                        return
                    }
                    let saved = state.confirmedBalance
                    state.seasonSelection = .init(commodityId: selection.commodityId, season: refreshedSeason)
                    state.confirmedBalance = saved.flatMap {
                        guard $0.commodityId == selection.commodityId, $0.seasonId == selection.season.id else { return nil }

                        return .init(commodityId: $0.commodityId, seasonId: $0.seasonId,
                            balance: .init(volume: $0.balance.volume, traceability: $0.balance.traceability, isCached: true))
                    }
                }
            }
        }

        @MainActor func stopBalanceRefresh() {
            balanceGeneration = UUID()
            isRefreshingBalance = false
        }

        func saveTransaction() {
            let alert = AlertManager.AlertModel(feature: AlertManager.AlertModel.Features.SaveTransaction.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .reviewInfo:
                        return nil
                    case .save:
                        return self.didTapSave
                }
            }
            showSaveConfirmation(alert)
        }

        func saveTransactionWithNoLocation() {
            let alert = AlertManager.AlertModel(feature: AlertManager.AlertModel.Features.SaveTransactionWithNoLocation.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .save:
                        return self.didTapSave
                    case .addFarmGeodata:
                        return nil
                }
            }
            showSaveConfirmation(alert)
        }

        private func showSaveConfirmation(_ alert: AlertManager.AlertModel) {
            guard !isSubmitting, !hasSaved, appState.createTransaction.value.draftID == draftID,
                  let draftGeneration, (try? draftGeneration.check()) != nil else { return }

            alertManager.show(businessModeInteractor.mode == .test
                ? alert.withInformation(AppLocale.TestMode.Confirmation.transaction) : alert)
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

        func didTapAutomaticInfo() {
            guard let breakdown = volumeBreakdown, breakdown.showsAutomatic else { return }

            alertManager.show(.init(
                title: AppLocale.CreateTransactionForm.Automatic.title,
                contentView: .init(Module.AutomaticInfoPopup())
            ))
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
            .map(\.confirmedBalance)
            .receive(on: DispatchQueue.main)
            .weakAssign(on: self, to: \.confirmedBalance)
            .store(in: cancellable)
        appState.createTransaction.state
            .map(\.seasonSelection)
            .receive(on: DispatchQueue.main)
            .weakAssign(on: self, to: \.seasonSelection)
            .store(in: cancellable)
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
        appState.createTransaction.dispatch {
            $0.draftID = draftID
            $0.transactionType = transactionType
        }
    }

    func didTapSave() {
        Task { @MainActor [weak self] in
            guard let self, let generation = self.draftGeneration else { return }

            await BusinessDataContext.$requestGeneration.withValue(generation) {
                await self.submitTransaction()
            }
        }
    }

    @MainActor
    func submitTransaction() async {
        guard !isSubmitting, !hasSaved, isSaveButtonEnabled,
              appState.createTransaction.value.draftID == draftID,
              let draftGeneration, (try? draftGeneration.check()) != nil else { return }

        isSubmitting = true
        appState.system[\.isLoading] = true
        defer {
            isSubmitting = false
            try? draftGeneration.whileCurrent { appState.system[\.isLoading] = false }
        }

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

                guard success, (try? draftGeneration.check()) != nil else { return }

                hasSaved = true
                popToRoot()
            case .downstream(let action, let recipient):
                let success = await self.createDownstreamTransactionRequest(
                    farmLocation: farmLocation,
                    commodityType: self.commodityType,
                    volume: self.volumeAmount,
                    action: action,
                    recipient: recipient
                )

                guard success, (try? draftGeneration.check()) != nil else { return }

                hasSaved = true
                popToRoot()
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

            let draft = appState.createTransaction.value
            let location = await locationService.getUserLocation()
            try businessDataContext.capture().check()
            guard draft.hasSameSubmissionInputs(as: appState.createTransaction.value), draft.commodityType.id == commodityType.id,
                  draft.volumeAmount == volume else { throw CreationSeasonError.invalidSelection }

            try await transactionsInteractor.createProducerTransaction(
                farmLocation: farmLocation,
                commodityType: commodityType,
                volume: volume,
                isBuyingFromFarmer: isBuyingFromFarmer,
                transactionCoordinates: location?.coordinate,
                inviteRecipient: inviteRecipient
            )

            return true
        } catch is CancellationError {
            return false
        } catch is CreationSeasonError {
            await appState.showError(message: Resources.AppLocale.CreationSeason.producerCatalogueRequired)
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
            let draft = appState.createTransaction.value
            let location = await locationService.getUserLocation()
            try businessDataContext.capture().check()
            guard draft.hasSameSubmissionInputs(as: appState.createTransaction.value), draft.commodityType.id == commodityType.id,
                  draft.volumeAmount == volume else { throw CreationSeasonError.invalidSelection }

            try await transactionsInteractor.createDownstreamTransaction(
                farmLocation: farmLocation,
                transactionCoordinates: location?.coordinate,
                commodityType: commodityType,
                volume: volume,
                action: action,
                recipient: recipient,
                seasonSelection: draft.seasonSelection
            )

            return true
        } catch let error as SeasonalSaleError {
            let message: String
            switch error {
                case .invalidQuantity:
                    message = AppLocale.CreationSeason.invalidQuantity
                case .insufficientBalance(let season):
                    message = AppLocale.CreationSeason.insufficientBalance(TransactionSeasonPresentation(season: season).title)
            }
            await appState.showError(message: message)
        } catch is CancellationError {
            return false
        } catch is CreationSeasonError {
            await appState.showError(message: Resources.AppLocale.CreationSeason.catalogueRequired)
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
