//
//  ConvertCommodityListViewModel.swift
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
import SwiftUI
import Utility
import RestClient

private typealias Module = ConvertCommodityListModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var items: IdentifiedArrayOf<ConversionRuleModel>
        @Published private(set) var showBottomLoader = false

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()
        private let commodityToConvert: CommodityGroupModel.Commodity
        private var pagination: ConvertCommodityInteractor.ConversionPagination?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.convertCommodityInteractor) private var convertCommodityInteractor

        // MARK: - Init
        init(commodity: CommodityGroupModel.Commodity) {
            self.commodityToConvert = commodity
            self.items = []

            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapOpenConverterDetails(model: ConversionRuleModel) {
            let screen: Screen = .convertCommodityDetails(commodity: commodityToConvert, convertionRule: model)
            appState.navigation[\.path].append(.push(screen))
        }

        func didPullLoadNextPage() async {
            guard pagination?.hasNextPage == true else { return }

            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = true
                }
            }

            await fetchConvertionRules(commodity: commodityToConvert, pagination: pagination)
            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = false
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func startup() {
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            await self.fetchConvertionRules(commodity: commodityToConvert, pagination: self.pagination)
        }
    }

    // MARK: - Common
    func fetchConvertionRules(
        commodity: CommodityGroupModel.Commodity,
        pagination: ConvertCommodityInteractor.ConversionPagination?
    ) async {
        do {
            let response = try await convertCommodityInteractor.fetchConversationRule(
                commodity: commodity,
                oldPagination: pagination,
                refresh: false
            )

            await MainActor.run { [weak self] in
                withAnimation(.snappy) {
                    self?.items += response.list
                    if !response.list.isEmpty {
                        self?.pagination = response.pagination
                    }
                }
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }
}
