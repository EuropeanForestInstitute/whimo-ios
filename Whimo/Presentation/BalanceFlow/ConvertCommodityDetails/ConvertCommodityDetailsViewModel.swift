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
import class CommonUI.AlertManager

private typealias Module = ConvertCommodityDetailsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var inputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init()
        @Published var outputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init()

        let commodity: CommodityGroupModel.Commodity
        let convertionRule: ConversionRuleModel
        let keyboardFields: IdentifiedArrayOf<KeyboardField>

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.convertCommodityInteractor) private var convertCommodityInteractor
        @Inject(\.transactionsInteractor) private var transactionsInteractor
        @Inject(\.balanceInteractor) private var balanceInteractor

        // MARK: - Init
        init(commodity: CommodityGroupModel.Commodity, convertionRule: ConversionRuleModel) {
            let inputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init(uniqueElements: convertionRule.inputs.map({ .init(from: $0) }))
            let outputCommodities: IdentifiedArrayOf<MutableConversionRule> = .init(uniqueElements: convertionRule.outputs.map({ .init(from: $0) }))
            let keyboardFields: IdentifiedArrayOf<KeyboardField> = .init(uniqueElements: (inputCommodities + outputCommodities).map({ .init(from: $0) }))

            self.inputCommodities = inputCommodities
            self.outputCommodities = outputCommodities
            self.keyboardFields = keyboardFields
            self.commodity = commodity
            self.convertionRule = convertionRule

            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapConvertCommodity() {
            alertManager.show(feature: AlertManager.AlertModel.Features.ConfirmCommodityConversion.self) { [weak self] key in
                guard let self else { return nil }

                switch key {
                    case .cancel:
                        return nil
                    case .convert:
                        return self.performConversion
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() { }

    func startup() { }

    // MARK: - Common
    func makeConversion(
        recipeId: String,
        inputOverrides: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>,
        outputCommodities: IdentifiedArrayOf<ConversionRuleModel.ConversionRuleItem>
    ) async -> Bool {
        do {
            try await convertCommodityInteractor.makeConversion(
                recipeId: recipeId,
                inputOverrides: inputOverrides,
                outputCommodities: outputCommodities
            )
            return true
        } catch {
            await appState.showError(message: error.localizedDescription)
            return false
        }
    }

    func refreshTransactionsList() async {
        do {
            try await transactionsInteractor.fetchTransactions(searchData: .empty, refresh: true)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func refreshBalancesList() async {
        do {
            try await balanceInteractor.fetchCommodityGroupsBalance()
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func openHomeScreen() {
        let navigationStackLevel = appState.navigation[\.path].count
        appState.navigation[\.path].removeLast(max(.zero, navigationStackLevel - 1))
        appState.system[\.selectedTab] = .home
    }

    func performConversion() {
        Task {
            await _performConversion()
        }
    }

    func _performConversion() async {
        self.appState.system[\.isLoading] = true
        defer { self.appState.system[\.isLoading] = false }

        let success = await makeConversion(
            recipeId: convertionRule.id,
            inputOverrides: .init(uniqueElements: inputCommodities.map({ $0.toDomain() })),
            outputCommodities: .init(uniqueElements: outputCommodities.map({ $0.toDomain() }))
        )

        guard success else { return }

        async let refreshTransactionsList: Void = refreshTransactionsList()
        async let refreshBalancesList: Void = refreshBalancesList()

        _ = await (refreshTransactionsList, refreshBalancesList)

        openHomeScreen()
    }
}
