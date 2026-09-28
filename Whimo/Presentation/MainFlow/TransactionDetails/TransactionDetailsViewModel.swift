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
        @Published private(set) var isRefreshing = false
        @Published private(set) var hasDetailsRefreshError = false
        @Published private(set) var isSubmittingStatus = false
        @Published private(set) var statusOutcome: TransactionModel.StatusOutcome?
        @Published private(set) var hasStatusRefreshError = false
        @Published private(set) var acceptanceBalance: ExactSeasonalBalance?
        @Published private(set) var isLoadingAcceptanceBalance = false
        @Published private(set) var hasAcceptanceBalanceError = false
        @Published private(set) var userModel: UserModel = .empty

        var requiresAcceptanceBalance: Bool {
            guard let value = transaction.value else { return false }

            return value.status == .pending && value.type == .downstream
                && value.seller?.id == userModel.id && value.createdById != userModel.id
        }

        var canAcceptTransaction: Bool {
            guard isCurrentBusinessContext, let value = transaction.value, value.status == .pending,
                  value.persistingData.state == .sync, waitingRecipientResponse, !isSubmittingStatus,
                  (try? profileLocalRepository.fetchProfile().id) == userModel.id else { return false }

            guard requiresAcceptanceBalance else { return true }
            guard acceptanceIdentity == loadedBalanceIdentity, let balance = acceptanceBalance,
                  let season = value.harvestSeason, season.id == value.harvestSeasonId else { return false }

            return season.status == .active || balance.volume >= value.volume
        }

        var acceptanceShortage: AcceptanceShortage? {
            guard requiresAcceptanceBalance, let identity = acceptanceIdentity,
                  identity == loadedBalanceIdentity, let balance = acceptanceBalance,
                  let value = transaction.value, let season = value.harvestSeason,
                  season.id == identity.seasonId, season.status != .active, balance.volume < value.volume else { return nil }

            return .init(available: balance.volume, requested: value.volume, unit: value.commodity.unit, season: season)
        }

        var acceptanceAutomaticPreview: AcceptanceAutomaticPreview? {
            guard requiresAcceptanceBalance, let identity = acceptanceIdentity,
                  identity == loadedBalanceIdentity, let balance = acceptanceBalance,
                  let value = transaction.value, let season = value.harvestSeason,
                  season.id == identity.seasonId, season.status == .active, balance.volume < value.volume else { return nil }

            return .init(quantity: value.volume - balance.volume, unit: value.commodity.unit)
        }

        var isAcceptanceBalanceUnavailable: Bool {
            requiresAcceptanceBalance && (acceptanceIdentity == nil || loadedBalanceIdentity != acceptanceIdentity
                || acceptanceBalance == nil || transaction.value?.harvestSeason?.id != transaction.value?.harvestSeasonId)
        }

        func showAcceptanceShortage() {
            guard let shortage = acceptanceShortage else { return }

            alertManager.show(.init(title: AppLocale.TransactionAcceptance.Balance.title,
                contentView: .init(AcceptanceShortagePopup(shortage: shortage)),
                buttons: [.init(title: AppLocale.TransactionAcceptance.Balance.gotIt)]))
        }

        private struct BalanceIdentity: Equatable {
            let participantId: String
            let commodityId: String
            let seasonId: String
        }
        private var loadedBalanceIdentity: BalanceIdentity?
        private var acceptanceIdentity: BalanceIdentity? {
            guard requiresAcceptanceBalance, let value = transaction.value,
                  let seasonId = value.harvestSeasonId, !seasonId.isEmpty,
                  (try? profileLocalRepository.fetchProfile().id) == userModel.id else { return nil }

            return .init(participantId: userModel.id, commodityId: value.commodity.id, seasonId: seasonId)
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private var fetchTask: Task<Void, Never>?
        private var pullRefreshTask: (id: UUID, task: Task<Void, Never>)?
        private var refreshGeneration = UUID()
        private var detailsGeneration: BusinessDataContext.Generation?
        private var isCurrentBusinessContext: Bool {
            guard let detailsGeneration else { return false }

            return (try? detailsGeneration.check()) != nil
        }
        private var acceptanceConfirmationID: UUID?
        private var hasAppeared = false
        private var isVisible = false
        private let transactionId: String

        // MARK: - Dependencies
        @Inject(\.businessDataContext) private var businessDataContext
        @Inject(\.businessModeInteractor) private var businessModeInteractor
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionListInteractor) private var transactionListInteractor
        @Inject(\.balanceListInteractor) private var balanceListInteractor
        @Inject(\.transactionsInteractor) private var transactionsInteractor
        @Inject(\.transactionsLocalRepository) private var transactionsLocalRepository
        @Inject(\.trxTraceabilityCachingRepository) private var trxTraceabilityRepository
        @Inject(\.profileLocalRepository) private var profileLocalRepository
        @Inject(\.transactionsRemoteRepository) private var transactionsRemoteRepository

        // MARK: - Init
        init(transactionId: String) {
            self.transactionId = transactionId
            detailsGeneration = try? businessDataContext.capture()

            setupBindings()
            startup()
        }

        deinit {
            log.debug()
        }

        // MARK: - ViewModelProtocol
        func showHarvestSeasonInfo() {
            guard let transaction = transaction.value else { return }

            alertManager.show(.init(
                title: AppLocale.HarvestSeasonPicker.Season.title,
                contentView: .init(HarvestSeasonInfoPopup(season: transaction.harvestSeason))
            ))
        }

        func showTraceabilityInfo() {
            typealias Localization = AppLocale.TransactionDetails.Popups.TraceabilityStatus

            alertManager.show(.init(
                title: Localization.title,
                subtitle: Localization.description,
                contentView: .init(TraceabilityStatusInfoPopup())
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
        @MainActor
        func didTapRejectTransaction() async {
            await submitStatus(.reject)
        }

        @MainActor
        func didTapAcceptTransaction() async {
            guard canAcceptTransaction else { return }

            guard businessModeInteractor.mode == .test else {
                await submitStatus(.accept)
                return
            }
            showAcceptanceConfirmation()
        }

        @MainActor
        private func showAcceptanceConfirmation() {
            guard acceptanceConfirmationID == nil, let pending = transaction.value else { return }

            let confirmationID = UUID()
            acceptanceConfirmationID = confirmationID
            let alert = AlertManager.AlertModel(
                title: AppLocale.TestMode.Acceptance.title,
                subtitle: AppLocale.TestMode.Acceptance.description,
                buttons: [
                    .init(title: AppLocale.TestMode.Acceptance.cancel, style: .bordered),
                    .init(title: AppLocale.TransactionDetails.ForMe.Buttons.accept, action: { [weak self] in
                        guard let self, self.acceptanceConfirmationID == confirmationID else { return }

                        self.acceptanceConfirmationID = nil
                        Task { @MainActor in
                            guard self.canAcceptTransaction, self.transaction.value == pending else { return }

                            await self.submitStatus(.accept)
                        }
                    })
                ],
                buttonsAxis: .vertical,
                onDismiss: { [weak self] in
                    guard self?.acceptanceConfirmationID == confirmationID else { return }

                    self?.acceptanceConfirmationID = nil
                }
            )
            alertManager.show(alert.withInformation(AppLocale.TestMode.Confirmation.acceptance))
        }

        @MainActor
        func onAppear() async {
            isVisible = true
            if !hasAppeared {
                hasAppeared = true
                if let fetchTask {
                    await fetchTask.value
                    return
                }
            }
            await refresh()
        }

        @MainActor
        func onForeground() async {
            guard isVisible else { return }

            await refresh()
        }

        @MainActor
        func onDisappear() {
            acceptanceConfirmationID = nil
            isVisible = false
            cancelRefresh()
        }

        @MainActor
        func didPullRefresh() async {
            guard isVisible else { return }

            if let pullRefreshTask {
                await pullRefreshTask.task.value
                return
            }
            guard !isRefreshing else { return }

            // SwiftUI may cancel the gesture task during an awaited read; Details owns its lifetime.
            let id = UUID()
            let task = Task<Void, Never> { @MainActor [weak self] in await self?.refresh() }
            pullRefreshTask = (id, task)
            await task.value
            if pullRefreshTask?.id == id { pullRefreshTask = nil }
        }

        @MainActor
        func refreshAcceptanceBalance() async {
            await refresh()
        }

        @MainActor
        func refresh() async {
            guard let detailsGeneration, isCurrentBusinessContext else { return }

            await BusinessDataContext.$requestGeneration.withValue(detailsGeneration) {
                await refreshInCurrentContext()
            }
        }

        @MainActor
        private func refreshInCurrentContext() async {
            guard !isRefreshing, !Task.isCancelled else { return }

            let generation = UUID()
            refreshGeneration = generation
            isRefreshing = true
            hasDetailsRefreshError = false
            defer {
                if refreshGeneration == generation {
                    isRefreshing = false
                    isLoadingAcceptanceBalance = false
                }
            }
            guard let profile = fetchUserProfile() else { return }

            userModel = profile
            let saved = try? await transactionsLocalRepository.fetchTransaction(by: transactionId)
            guard isCurrentRefresh(generation) else { return }

            if transaction.value == nil, let saved { transaction = .loaded(value: saved) }
            let initialIdentity = acceptanceIdentity
            async let details: Void = refreshDetails(generation: generation, stored: saved)
            async let balance: Void = loadAcceptanceBalance(generation: generation)
            _ = await (details, balance)
            if isCurrentRefresh(generation), acceptanceIdentity != initialIdentity, requiresAcceptanceBalance {
                await loadAcceptanceBalance(generation: generation)
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
            .compactMap { [weak self] list -> TransactionModel? in
                guard let self, case .loaded(let values) = list else { return nil }

                return values[id: self.transactionId]
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transaction in
                guard let self, self.isCurrentBusinessContext else { return }

                if let current = self.transaction.value {
                    guard transaction.id == current.id, transaction.commodity.id == current.commodity.id,
                          transaction.harvestSeasonId == current.harvestSeasonId,
                          transaction.status != .pending,
                          current.status == .pending || transaction.status == current.status else { return }
                }
                if let confirmed = self.statusOutcome?.transaction {
                    guard transaction.status == confirmed.status,
                          transaction.harvestSeasonId == confirmed.harvestSeasonId else { return }

                }
                var updated = transaction
                if updated.harvestSeason == nil { updated.harvestSeason = self.transaction.value?.harvestSeason }
                self.transaction = .loaded(value: updated)
            }
            .store(in: cancellable)
    }

    func startup() {
        fetchTask = Task { @MainActor [weak self] in
            await self?.refresh()
        }
    }

    @MainActor
    func cancelRefresh() {
        refreshGeneration = UUID()
        fetchTask?.cancel()
        fetchTask = nil
        pullRefreshTask?.task.cancel()
        pullRefreshTask = nil
        isRefreshing = false
        isLoadingAcceptanceBalance = false
    }

    @MainActor
    func isCurrentRefresh(_ generation: UUID) -> Bool {
        isCurrentBusinessContext && refreshGeneration == generation && !Task.isCancelled
            && (try? profileLocalRepository.fetchProfile().id) == userModel.id
    }

    @MainActor
    func loadAcceptanceBalance(generation: UUID) async {
        guard isCurrentRefresh(generation), requiresAcceptanceBalance else { return }

        isLoadingAcceptanceBalance = true
        hasAcceptanceBalanceError = false
        defer { if refreshGeneration == generation { isLoadingAcceptanceBalance = false } }
        guard let identity = acceptanceIdentity else {
            acceptanceBalance = nil
            hasAcceptanceBalanceError = true
            return
        }
        if loadedBalanceIdentity != identity { acceptanceBalance = nil }
        if acceptanceBalance == nil,
           let saved = try? await balanceListInteractor.cachedExact(commodityId: identity.commodityId, seasonId: identity.seasonId),
           isCurrentRefresh(generation), acceptanceIdentity == identity, saved.volume.isFinite, saved.volume >= 0 {
            acceptanceBalance = saved
            loadedBalanceIdentity = identity
        }
        guard isCurrentRefresh(generation), acceptanceIdentity == identity else { return }

        do {
            let balance = try await balanceListInteractor.exact(commodityId: identity.commodityId, seasonId: identity.seasonId)
            guard isCurrentRefresh(generation), acceptanceIdentity == identity else { return }
            guard balance.volume.isFinite, balance.volume >= 0 else { throw SeasonalBalanceError.incompleteResponse }

            acceptanceBalance = balance
            loadedBalanceIdentity = identity
            hasAcceptanceBalanceError = transaction.value?.harvestSeason?.id != identity.seasonId
        } catch {
            guard isCurrentRefresh(generation), acceptanceIdentity == identity, !(error is CancellationError) else { return }

            hasAcceptanceBalanceError = true
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

        let transactions = try await transactionsInteractor.fetchSuppliersTransactions(
            commodityGroupId: transaction.commodity.group.id,
            buyerId: sellerId,
            createdAtTo: transaction.updatedAt,
            oldPagination: nil,
            refresh: false
        )

        return transactions.list
    }

    @MainActor
    func refreshDetails(generation: UUID, stored: TransactionModel?) async {
        guard isCurrentRefresh(generation) else { return }

        if let saved = transaction.value, saved.persistingData.state != .sync {
            transactionState = saved.persistingData.state
            supplierTransactions = .loaded(value: [])
            pieChartData = .loaded(value: .init(items: []))
            return
        }
        do {
            var updated = try await transactionsInteractor.refreshTransactionDetails(by: transactionId)
            guard isCurrentRefresh(generation) else { return }
            guard updated.id == transactionId else { throw SeasonalBalanceError.incompleteResponse }

            if let previous = transaction.value {
                guard updated.commodity.id == previous.commodity.id,
                      updated.harvestSeasonId == nil || previous.harvestSeasonId == nil
                        || updated.harvestSeasonId == previous.harvestSeasonId else { throw SeasonalBalanceError.incompleteResponse }

                if updated.harvestSeasonId == nil { updated.harvestSeasonId = previous.harvestSeasonId }
                if updated.harvestSeason == nil { updated.harvestSeason = previous.harvestSeason }
                // A completed status operation cannot be undone by a delayed Pending read.
                if previous.status != .pending, updated.status == .pending { updated = previous }
            }
            if let confirmed = statusOutcome?.transaction, updated.status != confirmed.status { updated = confirmed }
            transaction = .loaded(value: updated)
            transactionState = updated.persistingData.state
            if acceptanceBalance != nil { hasAcceptanceBalanceError = isAcceptanceBalanceUnavailable }
            if let stored { try await transactionsInteractor.cacheTransactionDetails(updated, replacing: stored) }
            guard isCurrentRefresh(generation) else { return }

            let snapshot = updated
            async let suppliers = snapshot.status.goodStatus ? fetchSuppliersHistory(transaction: snapshot) : []
            async let traceability: TransactionTraceabilityModel? = snapshot.traceability != nil
                ? trxTraceabilityRepository.fetchTransactionTraceability(by: snapshot.id) : nil
            let history = try await suppliers
            let chart = try await traceability
            guard isCurrentRefresh(generation) else { return }

            supplierTransactions = .loaded(value: history)
            pieChartData = .loaded(value: chart ?? .init(items: []))
        } catch {
            guard isCurrentRefresh(generation), !(error is CancellationError) else { return }

            hasDetailsRefreshError = true
            if statusOutcome != nil { hasStatusRefreshError = true }
            await appState.showError(message: statusOutcome == nil
                ? AppLocale.TransactionAcceptance.detailsRefreshFailed : AppLocale.TransactionAcceptance.refreshFailed)
        }
    }

    @MainActor
    func submitStatus(_ status: TransactionModel.StatusChange) async {
        guard let detailsGeneration, isCurrentBusinessContext else { return }

        await BusinessDataContext.$requestGeneration.withValue(detailsGeneration) {
            await submitStatusInCurrentContext(status)
        }
    }

    @MainActor
    func submitStatusInCurrentContext(_ status: TransactionModel.StatusChange) async {
        guard !isSubmittingStatus, let pending = transaction.value, pending.status == .pending,
              pending.persistingData.state == .sync,
              waitingRecipientResponse || waitingCreatorResponse,
              (try? profileLocalRepository.fetchProfile().id) == userModel.id else { return }

        acceptanceConfirmationID = nil
        isSubmittingStatus = true
        appState.system[\.isLoading] = true
        defer {
            isSubmittingStatus = false
            try? detailsGeneration?.whileCurrent { appState.system[\.isLoading] = false }
        }
        do {
            let outcome = try await transactionsInteractor.updateTransaction(pending, status: status)
            guard isCurrentBusinessContext else { return }

            cancelRefresh()
            statusOutcome = outcome
            transaction = .loaded(value: outcome.transaction)
            hasStatusRefreshError = outcome.cacheSaveFailed
            presentStatusOutcome(outcome)
            await refreshAfterStatusChange(outcome.transaction)
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentBusinessContext else { return }

            let message: String
            if case TransactionModel.StatusChangeError.conflict = error {
                message = AppLocale.TransactionAcceptance.conflict
                cancelRefresh()
                await refresh()
            } else {
                message = AppLocale.TransactionAcceptance.unconfirmed
            }
            guard isCurrentBusinessContext else { return }

            await appState.showError(message: message)
        }
    }

    @MainActor
    func presentStatusOutcome(_ outcome: TransactionModel.StatusOutcome) {
        let message: String
        if let automatic = outcome.automaticTransaction {
            let volume = automatic.volume.formatted()
            message = AppLocale.TransactionAcceptance.automatic(volume, automatic.commodity.unit)
        } else {
            message = outcome.transaction.status == .accepted
                ? AppLocale.TransactionAcceptance.accepted : AppLocale.TransactionAcceptance.rejected
        }
        alertManager.show(.init(title: outcome.transaction.status.title, subtitle: message))
    }

    @MainActor
    func refreshAfterStatusChange(_ confirmed: TransactionModel) async {
        async let transactionsRefresh: Void = transactionListInteractor.refresh(cacheOnly: false)
        async let balanceRefresh: Void = balanceListInteractor.refresh(cacheOnly: false)
        if confirmed.status.goodStatus {
            do {
                async let suppliers = fetchSuppliersHistory(transaction: confirmed)
                async let traceability: TransactionTraceabilityModel? = confirmed.traceability != nil
                    ? trxTraceabilityRepository.fetchTransactionTraceability(by: confirmed.id) : nil
                let history = try await suppliers
                let chart = try await traceability
                guard isCurrentBusinessContext else { return }

                supplierTransactions = .loaded(value: history)
                pieChartData = .loaded(value: chart ?? .init(items: []))
            } catch {
                guard isCurrentBusinessContext else { return }

                hasStatusRefreshError = true
            }
        }
        await transactionsRefresh
        await balanceRefresh
        guard isCurrentBusinessContext else { return }

        hasStatusRefreshError = hasStatusRefreshError || appState.transactions.value.hasListError || appState.balance.value.hasListError
        if hasStatusRefreshError {
            await appState.showError(message: AppLocale.TransactionAcceptance.refreshFailed)
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
