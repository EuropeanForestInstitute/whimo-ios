//
//  CommoditiesListViewModel.swift
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

import Foundation
import Utility

private typealias Module = CommoditiesListModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var list: IdentifiedArrayOf<CommodityGroupModel> = []
        @Published var selectedRow: CommodityGroupModel.Commodity = .initialState

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.commoditiesService) private var commoditiesService

        // MARK: - Init
        init() {
            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirm() {
            guard selectedRow != .initialState else { return }

            Task.detached { [commoditiesService = commoditiesService, selectedRow = selectedRow] in
                try? await commoditiesService.fetchBalance(commodityId: selectedRow.id)
            }

            appState.createTransaction[\.commodityType] = selectedRow
            appState.navigation[\.path].removeLast()
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
            .animatedAssign(on: self, to: \.selectedRow)
            .store(in: cancellable)
    }

    func startup() {
        Task { [weak self] in
            self?.appState.system[\.isLoading] = true
            defer { self?.appState.system[\.isLoading] = false }

            await self?.fetchCommodities()
        }
    }

    // MARK: - Common
    func fetchCommodities() async {
        do {
            let groupsList = try await commoditiesService.fetchCommodityGroups()
            await MainActor.run {
                list = groupsList
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }
}
