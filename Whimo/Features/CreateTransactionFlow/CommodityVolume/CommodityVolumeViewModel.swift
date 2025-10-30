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
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var volumeText: String = ""
        @Published private(set) var commodityType: CommodityGroupModel.Commodity
        @Published private(set) var enableNoteBanner: Bool = false

        // MARK: - Private Properties
        private let transactionType: TransactionType
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.commoditiesService) private var commoditiesService

        // MARK: - Init
        init(
            volumeAmount: String,
            commodityType: CommodityGroupModel.Commodity,
            transactionType: TransactionType
        ) {
            self.volumeText = volumeAmount
            self.commodityType = commodityType
            self.transactionType = transactionType

            setupBinding()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirm() {
            if !volumeText.isEmpty {
                appState.createTransaction[\.volumeAmount] = volumeText
            }

            appState.navigation[\.path].removeLast()
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.createTransaction.state
            .map(\.balances)
            .combineLatest($volumeText)
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] balances, volumeText in
                guard let self else { return }

                let balance = balances.first
                let status = self.getBannerStatus(
                    balance: balance,
                    transactionType: self.transactionType,
                    volumeText: volumeText
                )

                withAnimation(.snappy) {
                    self.enableNoteBanner = status
                }
            }
            .store(in: cancellable)
        appState.createTransaction.state
            .map(\.commodityType)
            .receive(on: DispatchQueue.main)
            .weakAssign(on: self, to: \.commodityType)
            .store(in: cancellable)
    }

    // MARK: - Common
    func getBannerStatus(
        balance: CommodityBalanceModel?,
        transactionType: TransactionType,
        volumeText: String
    ) -> Bool {
        let status: Bool
        if case .downstream(let action, _) = transactionType,
           action == .sell,
           let volume: Double = .init(volumeText),
           volume > balance?.volume ?? .zero {
            status = true
        } else {
            status = false
        }

        return status
    }
}
