//
//  SuppliersHistoryViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.06.2025.
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
import class CommonUI.AlertManager
import RestClient

private typealias Module = SuppliersHistoryModule
private typealias ViewModel = Module.ViewModel

extension Module {
    // MARK: - ViewModel
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var list: IdentifiedArrayOf<SupplierTransactionModel> = []
        @Published private(set) var showBottomLoader = false
        @Published var showExporter: ExporterPresentation?

        let supplierInfo: SupplierInfo

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()
        private var pagination: RequestModels.TransactionsList?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionsInteractor) private var transactionsInteractor
        @Inject(\.transactionsRemoteRepository) private var transactionsRemoteRepository
        @Inject(\.transactionDocumentsService) private var transactionDocumentsService

        // MARK: - Init
        init(supplierInfo: SupplierInfo) {
            self.supplierInfo = supplierInfo
            startup()
        }

        // MARK: - ViewModelProtocol
        func didPullLoadNextPage() async {
            guard pagination?.hasNextPage == true else { return }

            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = true
                }
            }

            await fetchSuppliersHistory(supplierInfo: supplierInfo, pagination: pagination)
            await MainActor.run {
                withAnimation(.snappy) {
                    showBottomLoader = false
                }
            }
        }

        func didTapBackToRoot() {
            let navigationStack = appState.navigation.value.path

            for route in navigationStack.reversed() {
                if case .suppliersHistory(let supplierInfo) = route.screen {
                    switch supplierInfo.supplierType {
                        case .mySupplier:
                            continue
                        case .other:
                            appState.navigation[\.path].removeLast()
                            continue
                    }
                } else {
                    break
                }
            }
        }

        func didTapSupplierRow(_ item: SupplierTransactionModel) {
            guard
                let supplierInfo: SuppliersHistoryModule.SupplierInfo = .init(from: item)
            else { return }

            let screen: Screen = .suppliersHistory(supplierInfo: supplierInfo)
            appState.navigation[\.path].append(.push(screen))
        }

        func showDowloadZipAlert() {
            typealias AlertType = AlertManager.AlertModel.Features.DownloadLocations
            var alert = AlertType.alert
            alert.contentView = .init(DownloadTxDetailsModule.FarmLocationsPopup())

            let buttons: [AlertManager.AlertModel.Button] = AlertType.ActionKeys.allCases.map { key in
                var button = key.button
                switch key {
                    case .cancel:
                        return button
                    case .download:
                        button.action = didTapZipLocations
                        return button
                }
            }
            alert.buttons = buttons

            alertManager.show(alert)
        }

        func didTapRequestLocation() {
            alertManager.show(
                feature: AlertManager.AlertModel.Features.RequestMissingLocation.self
            ) { [requestMissingLocation = requestMissingLocation] key in
                switch key {
                    case .request:
                        return requestMissingLocation
                    case .cancel:
                        return nil
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

            await self.fetchSuppliersHistory(supplierInfo: supplierInfo, pagination: self.pagination)
        }
    }

    // MARK: - Common
    func fetchSuppliersHistory(
        supplierInfo: Module.SupplierInfo,
        pagination: RequestModels.TransactionsList?
    ) async {
        do {
            let transactions = try await transactionsInteractor.fetchSuppliersTransactions(
                commodityGroupId: supplierInfo.commodityGroupId,
                buyerId: supplierInfo.supplier.id,
                oldPagination: pagination,
                refresh: false
            )

            await MainActor.run { [weak self] in
                withAnimation(.snappy) {
                    self?.list += transactions.list
                    if !transactions.list.isEmpty {
                        self?.pagination = transactions.pagination
                    }
                }
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func requestMissingLocation() async {
        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        do {
            let success = try await transactionsRemoteRepository.requestTransactionGeodata(transactionId: supplierInfo.transactionId)
            await appState.showInfo(message: success.message)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func requestMissingLocation() {
        Task { [weak self] in await self?.requestMissingLocation() }
    }

    func downloadZip(transactionId: String) async {
        do {
            let zipFile = try await transactionDocumentsService.downloadDocumentsBundle(transactionId: transactionId)
            await MainActor.run { [weak self] in
                self?.showExporter = .showZipExporter(file: zipFile)
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func didTapZipLocations() {
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            let transactionId = self.supplierInfo.transactionId
            await self.downloadZip(transactionId: transactionId)
        }
    }
}
