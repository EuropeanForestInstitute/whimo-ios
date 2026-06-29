//
//  BalanceGroupsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.08.2025.
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

private typealias Module = BalanceGroupsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var commodityGroups: Loadable<IdentifiedArrayOf<CommodityGroupModel>> = .notRequested

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.balanceInteractor) private var balanceInteractor

        // MARK: - Init
        init() {
            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didPullRefresh() async {
            let refreshTask = Task { [weak self] in
                guard let self else { return }

                await self.fetchCommodities()
            }

            _ = await refreshTask.result
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        // Observe balance state for commodity groups
        appState.balance.state
            .map(\.commodityGroups)
            .receive(on: DispatchQueue.main)
            .assign(to: \.commodityGroups, on: self)
            .store(in: cancellable)
    }

    func startup() { }

    // MARK: - Common
    func fetchCommodities() async {
        do {
            try await balanceInteractor.fetchCommodityGroupsBalance()
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }
}
