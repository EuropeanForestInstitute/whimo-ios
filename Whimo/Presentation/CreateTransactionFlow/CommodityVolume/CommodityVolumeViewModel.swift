//
//  CommodityVolumeViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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

private typealias Module = CommodityVolumeModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    @MainActor
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var volumeText: String = ""
        @Published private(set) var commodityType: CommodityGroupModel.Commodity

        @Published private(set) var seasons: [HarvestSeason] = []
        @Published private(set) var selectedSeason: HarvestSeason?
        @Published private(set) var seasonalBalance: ExactSeasonalBalance?
        @Published private(set) var catalogueUnavailable = false
        @Published private(set) var isLoadingSeasons = false
        @Published private(set) var balanceUnavailable = false

        var requiresSeason: Bool {
            if case .downstream = transactionType { return true }
            return false
        }

        var isSelling: Bool {
            if case .downstream(.sell, _) = transactionType { return true }
            return false
        }

        var saleValidation: SeasonalSaleValidation {
            .init(volume: volumeText, season: selectedSeason, balance: seasonalBalance)
        }

        var enableNoteBanner: Bool { isSelling && saleValidation == .activeShortage }
        var hasSeasonalShortage: Bool { isSelling && saleValidation == .seasonalShortage }

        var canConfirm: Bool {
            guard !volumeText.isEmpty else { return false }
            guard requiresSeason else { return true }
            return loadedCommodityId == commodityType.id && selectedSeason != nil && !isLoadingSeasons
                && appState.createTransaction.value.commodityType.id == commodityType.id
                && (!isSelling || ((seasonalBalance != nil || balanceUnavailable) && saleValidation.permitsSale))
        }

        // MARK: - Private Properties
        private var loadedCommodityId: String?
        private var catalogueGeneration = UUID()
        private var balanceGeneration = UUID()
        private let transactionType: TransactionType
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.creationSeasonInteractor) private var creationSeasonInteractor

        // MARK: - Init
        init(
            volumeAmount: String,
            commodityType: CommodityGroupModel.Commodity,
            transactionType: TransactionType
        ) {
            self.volumeText = volumeAmount
            self.commodityType = commodityType
            self.transactionType = transactionType

            self.selectedSeason = appState.createTransaction.value.seasonSelection?.season
            setupBinding()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirm() {
            guard canConfirm else { return }

            appState.createTransaction.dispatch { state in
                state.volumeAmount = volumeText
                if requiresSeason, let selectedSeason {
                    state.seasonSelection = .init(commodityId: commodityType.id, season: selectedSeason)
                    state.confirmedBalance = isSelling ? seasonalBalance.map {
                        .init(commodityId: commodityType.id, seasonId: selectedSeason.id, balance: $0)
                    } : nil
                }
            }
            if !appState.navigation.value.path.isEmpty { appState.navigation[\.path].removeLast() }
        }

        func loadSeasons() async {
            guard requiresSeason else { return }

            let commodityId = commodityType.id
            let generation = UUID()
            catalogueGeneration = generation
            balanceGeneration = UUID()
            balanceUnavailable = false
            loadedCommodityId = nil
            isLoadingSeasons = true
            catalogueUnavailable = false
            seasons = []
            seasonalBalance = nil
            let previousId = selectedSeason?.id
            do {
                let catalogue = try await creationSeasonInteractor.seasons(commodityId: commodityId)
                try Task.checkCancellation()
                guard catalogueGeneration == generation, commodityType.id == commodityId,
                      appState.createTransaction.value.commodityType.id == commodityId else { return }

                seasons = catalogue.values
                selectedSeason = seasons.first(where: { $0.id == previousId })
                    ?? seasons.first(where: { $0.status == .active })
                loadedCommodityId = commodityId
                catalogueUnavailable = seasons.isEmpty
                isLoadingSeasons = false
            } catch {
                guard catalogueGeneration == generation else { return }

                isLoadingSeasons = false
                guard !Task.isCancelled else { return }

                selectedSeason = nil
                catalogueUnavailable = true
            }
        }

        func selectSeason(_ season: HarvestSeason) {
            guard loadedCommodityId == commodityType.id,
                  let covered = seasons.first(where: { $0.id == season.id }) else { return }

            balanceGeneration = UUID()
            balanceUnavailable = false
            selectedSeason = covered
            seasonalBalance = nil
        }

        func loadBalance() async {
            guard requiresSeason, loadedCommodityId == commodityType.id, let selectedSeason else { return }

            let commodityId = commodityType.id
            let seasonId = selectedSeason.id
            let generation = UUID()
            balanceGeneration = generation
            seasonalBalance = nil
            balanceUnavailable = false
            do {
                let balance = try await creationSeasonInteractor.balance(commodityId: commodityId, seasonId: seasonId)
                try Task.checkCancellation()
                guard balanceGeneration == generation, self.selectedSeason?.id == seasonId,
                      commodityType.id == commodityId, loadedCommodityId == commodityId,
                      appState.createTransaction.value.commodityType.id == commodityId else { return }

                seasonalBalance = balance
            } catch is CancellationError {
                return
            } catch {
                guard balanceGeneration == generation, self.selectedSeason?.id == seasonId,
                      commodityType.id == commodityId, loadedCommodityId == commodityId,
                      appState.createTransaction.value.commodityType.id == commodityId, !Task.isCancelled else { return }

                balanceUnavailable = true
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.createTransaction.state
            .map(\.commodityType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] commodity in
                guard let self else { return }

                if self.commodityType.id != commodity.id {
                    self.catalogueGeneration = UUID()
                    self.balanceGeneration = UUID()
                    self.loadedCommodityId = nil
                    self.balanceUnavailable = false
                    self.seasonalBalance = nil
                }
                self.commodityType = commodity
            }
            .store(in: cancellable)
    }

}
