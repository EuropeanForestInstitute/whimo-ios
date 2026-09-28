//
//  ConvertCommodityDetailsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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
import Utility
import Resources
import class CommonUI.AlertManager

private typealias Module = ConvertCommodityDetailsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    @MainActor
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var inputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init()
        @Published var outputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init()
        @Published private(set) var isSubmitting = false
        @Published private(set) var hasConverted = false

        let commodity: CommodityGroupModel.Commodity
        let convertionRule: ConversionRuleModel
        let season: HarvestSeason?
        let keyboardFields: IdentifiedArrayOf<KeyboardField>

        private var draftGeneration: BusinessDataContext.Generation?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.businessModeInteractor) private var businessModeInteractor
        @Inject(\.businessDataContext) private var businessDataContext
        @Inject(\.alertManager) private var alertManager
        @Inject(\.convertCommodityInteractor) private var convertCommodityInteractor
        @Inject(\.transactionListInteractor) private var transactionsInteractor
        @Inject(\.balanceListInteractor) private var balanceInteractor

        // MARK: - Init
        init(commodity: CommodityGroupModel.Commodity, convertionRule: ConversionRuleModel, season: HarvestSeason? = nil) {
            let inputs: IdentifiedArrayOf<MutableConversionRule> = .init(uniqueElements: convertionRule.inputs.map { .init(from: $0) })
            let outputs: IdentifiedArrayOf<MutableConversionRule> = .init(uniqueElements: convertionRule.outputs.map { .init(from: $0) })
            self.inputCommodities = inputs
            self.outputCommodities = outputs
            self.keyboardFields = .init(uniqueElements: (inputs + outputs).map { .init(from: $0) })
            self.commodity = commodity
            self.convertionRule = convertionRule
            self.season = season
            draftGeneration = try? businessDataContext.capture()
        }

        // MARK: - Actions
        func didTapConvertCommodity() {
            guard !isSubmitting, !hasConverted, let draftGeneration,
                  (try? draftGeneration.check()) != nil else { return }

            let alert = AlertManager.AlertModel(feature: AlertManager.AlertModel.Features.ConfirmCommodityConversion.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .cancel:
                        return nil
                    case .convert:
                        return { Task { await self.submitConversion() } }
                }
            }
            alertManager.show(businessModeInteractor.mode == .test
                ? alert.withInformation(AppLocale.TestMode.Confirmation.conversion) : alert)
        }

        func submitConversion() async {
            guard let draftGeneration else { return }

            await BusinessDataContext.$requestGeneration.withValue(draftGeneration) {
                await performConversion()
            }
        }

        private func performConversion() async {
            guard !isSubmitting, !hasConverted, let draftGeneration,
                  (try? draftGeneration.check()) != nil else { return }
            guard let season else {
                await appState.showError(message: AppLocale.ConversionSeason.coverage)
                return
            }

            isSubmitting = true
            appState.system[\.isLoading] = true
            defer {
                isSubmitting = false
                try? draftGeneration.whileCurrent { appState.system[\.isLoading] = false }
            }

            do {
                try await convertCommodityInteractor.makeConversion(
                    rule: convertionRule,
                    seasonId: season.id,
                    inputOverrides: .init(uniqueElements: inputCommodities.map { $0.toDomain() }),
                    outputCommodities: .init(uniqueElements: outputCommodities.map { $0.toDomain() })
                )
            } catch is CancellationError {
                return
            } catch {
                await appState.showError(message: message(for: error))
                return
            }

            guard (try? draftGeneration.check()) != nil else { return }

            // Once confirmed, a failed refresh must never make this form submit again.
            hasConverted = true
            async let transactions: Void = transactionsInteractor.refresh(cacheOnly: false)
            async let balances: Void = balanceInteractor.refresh(cacheOnly: false)
            _ = await (transactions, balances)

            guard (try? draftGeneration.check()) != nil else { return }

            let count = appState.navigation[\.path].count
            appState.navigation[\.path].removeLast(max(.zero, count - 1))
            appState.system[\.selectedTab] = .balance
            if appState.balance.value.hasListError || appState.transactions.value.hasListError {
                await appState.showError(message: AppLocale.ConversionSeason.refreshFailed)
            }
        }

        private func message(for error: Error) -> String {
            switch error {
                case ConversionError.coverage:
                    AppLocale.ConversionSeason.coverage
                case ConversionError.insufficientBalance:
                    AppLocale.ConversionSeason.insufficientBalance
                default:
                    AppLocale.ConversionSeason.unavailable
            }
        }
    }
}
