//
//  TransactionDetailsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.05.2025.
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
import RestClient
import Utility
import Resources
import class CommonUI.AlertManager

private typealias Module = TransactionDetailsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var transaction: Loadable<TransactionModel> = .notRequested
        @Published private(set) var transactionState: TransactionModel.PersistingData.State = .sync
        @Published private(set) var pieChartData: Loadable<TransactionTraceabilityModel> = .notRequested
        @Published private(set) var supplierTransactions: Loadable<IdentifiedArrayOf<SupplierTransactionModel>> = .notRequested
        @Published private(set) var userModel: UserModel = .empty

        var rows: IdentifiedArrayOf<Row> {
            do {
                let optionalStatus = transaction.value?.status
                let status = try optionalStatus.unwrap()

                switch status {
                    case .automatic:
                        return .init(uniqueElements: Row.automaticStatusCases)
                    case .pending:
                        return .init(uniqueElements: Row.pendingStatusCases)
                    default:
                        return .init(uniqueElements: Row.plainStatusCases)
                }
            } catch {
                return []
            }
        }
        var waitingCreatorResponse: Bool {
            transaction.value?.status == .pending
            && transaction.value?.createdById == userModel.id
        }
        var waitingRecipientResponse: Bool {
            transaction.value?.status == .pending
            && transaction.value?.createdById != userModel.id
        }
        var isLoaded: Bool {
            transaction.isLoaded
            && pieChartData.isLoaded
            && supplierTransactions.isLoaded
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private var fetchTask: Task<Void, Never>?
        private let transactionId: String

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionService) private var transactionService
        @Inject(\.transactionsLocalRepository) private var transactionsLocalRepository
        @Inject(\.trxTraceabilityCachingRepository) private var trxTraceabilityRepository
        @Inject(\.profileLocalRepository) private var profileLocalRepository
        @Inject(\.transactionsRemoteRepository) private var transactionsRemoteRepository

        // MARK: - Init
        init(transactionId: String) {
            self.transactionId = transactionId

            setupBindings()
            startup()
        }

        deinit {
            log.debug()
        }

        // MARK: - ViewModelProtocol
        func showTraceabilityInfo() {
            typealias Localization = AppLocale.TransactionDetails.Popups.TraceabilityStatus

            alertManager.show(.init(
                title: Localization.title,
                subtitle: Localization.description,
                contentView: .init(TraceabilityStatusPopup())
            ))
        }

        func showRecipientInfo() {
            typealias Localization = AppLocale.TransactionDetails.Popups.CounterpartyInfo

            guard let transaction = transaction.value else { return }

            let title: String

            switch transaction.action {
                case .buy:
                    title = Localization.sellerTitle
                case .sell:
                    title = Localization.buyerTitle
            }

            alertManager.show(.init(
                title: title,
                contentView: .init(RecipientInfoPopup(transaction: transaction))
            ))
        }

        func showTransactionInfo() {
            alertManager.show(.init(
                title: transaction.value?.status.title ?? "",
                subtitle: transaction.value?.status.details
            ))
        }

        func didTapShowSupplierHistory() {
            guard
                let transaction = transaction.value,
                let supplierInfo: SuppliersHistoryModule.SupplierInfo = .init(from: transaction)
            else { return }

            let screen: Screen = .suppliersHistory(supplierInfo: supplierInfo)
            appState.navigation[\.path].append(.push(screen))
        }

        // MARK: - Update Transaction Status
        func didTapRejectTransaction() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            do {
                let transactionId = transaction.value?.id ?? ""
                try await updateTransaction(transactionId: transactionId, status: .reject)
            } catch {
                await appState.showError(message: error.localizedDescription)
            }
        }

        func didTapAcceptTransaction() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            do {
                let transactionId = transaction.value?.id ?? ""
                try await updateTransaction(transactionId: transactionId, status: .accept)
                try await fetchTransactionDetails(transactionId: transactionId)
            } catch {
                await appState.showError(message: error.localizedDescription)
            }
        }

        func didTapResendNotification() async {
            await requestMissingLocation(transactionId: transactionId)
        }

        func didTapAddMissignGeodata() {
            let screen: Screen = .uploadFile(mode: .fileUploader(transactionId: transaction.value?.id ?? ""))
            appState.navigation[\.path].append(.push(screen))
        }

        func didTapSupplyRow(_ item: SupplierTransactionModel) {
            guard
                let supplierInfo: SuppliersHistoryModule.SupplierInfo = .init(from: item)
            else { return }

            let screen: Screen = .suppliersHistory(supplierInfo: supplierInfo)
            appState.navigation[\.path].append(.push(screen))
        }

        func didTapOpenDowloadView() {
            let data = (pieChartData.value?.items ?? []).filter { $0.value > .zero }
            let tradersCount: Int = .init(data.reduce(into: .zero) { partialResult, item in
                partialResult += item.value
            })

            let screen: Screen = .downloadTxDetails(transactionId: transactionId, tradersCount: tradersCount)
            appState.navigation[\.path].append(.sheet(screen))
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBindings() {
        appState.transactions.state
            .dropFirst()
            .map(\.list)
            .map { [weak self] transactions -> Loadable<TransactionModel>? in
                guard let self else { return nil }

                switch transactions {
                    case .notRequested:
                        return .notRequested
                    case .requested(let lastValue):
                        guard
                            let value = lastValue?[id: self.transactionId]
                        else { return .requested(lastValue: nil) }

                        return .requested(lastValue: value)
                    case .isLoading(let lastValue):
                        let array = lastValue ?? []
                        guard
                            let value = array[id: self.transactionId]
                        else { return nil }

                        return .isLoading(lastValue: value)
                    case .loaded(let value):
                        guard
                            let value = value[id: self.transactionId]
                        else { return nil }

                        return .loaded(value: value)
                    case .failed:
                        return nil
                }
            }
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .weakAssign(on: self, to: \.transaction)
            .store(in: cancellable)
    }

    func startup() {
        fetchTask = Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            guard
                let userModel = fetchUserProfile()
            else { return }

            await MainActor.run {
                self.userModel = userModel
            }
            try await fetchTransactionDetails(transactionId: transactionId)
        } catch: { [weak self] error in
            self?.appState.showError(message: error.localizedDescription)
        }
    }

    // MARK: - Common
    func fetchUserProfile() -> UserModel? {
        do {
            let userProfile = try profileLocalRepository.fetchProfile()
            return userProfile
        } catch {
            appState.showError(message: error.localizedDescription)
        }

        return nil
    }

    func fetchSuppliersHistory(transaction: TransactionModel) async throws -> IdentifiedArrayOf<SupplierTransactionModel> {
        guard let sellerId = transaction.seller?.id else {
            log.debug("Cannot fetch suppliers history. No seller ID.")
            return []
        }

        let transactions = try await transactionService.fetchSuppliersTransactions(
            commodityGroupId: transaction.commodity.group.id,
            buyerId: sellerId,
            oldPagination: nil,
            refresh: false
        )

        return transactions.list
    }

    func fetchTransactionDetails(transactionId: String) async throws {
        await MainActor.run { [weak self] in
            guard let self else { return }

            self.transaction.setIsLoading()
            self.pieChartData.setIsLoading()
            self.supplierTransactions.setIsLoading()
        }

        let preloadedTransaction = try await transactionsLocalRepository.fetchTransaction(by: transactionId)
        if case .sync = preloadedTransaction.persistingData.state {
            let transaction = try await transactionService.fetchTransaction(by: transactionId)
            async let supplierTransactionsTask = transaction.status.goodStatus
            ? fetchSuppliersHistory(transaction: transaction)
            : []
            async let pieChartDataTask: TransactionTraceabilityModel? = transaction.traceability != nil
            ? trxTraceabilityRepository.fetchTransactionTraceability(by: transaction.id)
            : nil

            let supplierTransactions = try await supplierTransactionsTask
            let pieChartData = try await pieChartDataTask

            await MainActor.run { [weak self, transaction] in
                guard let self else { return }

                self.transaction = .loaded(value: transaction)
                self.supplierTransactions = .loaded(value: supplierTransactions)
                if let pieChartData {
                    self.pieChartData = .loaded(value: pieChartData)
                } else {
                    self.pieChartData = .loaded(value: TransactionTraceabilityModel(items: []))
                }
                self.transactionState = .sync
            }
            return
        }

        await MainActor.run { [weak self] in
            guard let self else { return }

            self.transaction = .loaded(value: preloadedTransaction)
            self.supplierTransactions = .loaded(value: [])
            self.pieChartData = .loaded(value: TransactionTraceabilityModel(items: []))
            self.transactionState = .onDisk
        }
    }

    func updateTransaction(transactionId: String, status: RequestModels.UpdateTransactionStatus.Status) async throws {
        let updatedTransaction = try await transactionService.updateTransaction(transactionId: transactionId, status: status)
        await MainActor.run { [weak self] in
            self?.transaction = .loaded(value: updatedTransaction)
        }
    }

    func requestMissingLocation(transactionId: String) async {
        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        do {
            let success = try await transactionsRemoteRepository.resendTransactionNotification(transactionId: transactionId)
            await appState.showInfo(message: success.message)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }
}
