//
//  AppInitializationInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 16.07.2025.
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
import Networking
import RestClient

actor DataFetcherInteractorImpl: DataFetcherInteractor {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let profileInteractor: ProfileInteractor
    private let notificationsSettingsInteractor: NotificationsSettingsInteractor
    private let transactionsInteractor: TransactionListInteractor
    private let balanceInteractor: BalanceListInteractor
    private let notificationsInteractor: NotificationsInteractor

    private let connectivity: any Connectivity
    private let commodityRepository: CommodityCachingRepository
    private let seasonRepository: SeasonCatalogueRepository
    private let accountId: () -> String?
    private var catalogueTask: Task<Void, Never>?
    private var catalogueGeneration = UUID()
    private var hasPendingCatalogueRetry = false

    // MARK: - Init
    init(
        profileInteractor: ProfileInteractor,
        notificationsSettingsInteractor: NotificationsSettingsInteractor,
        transactionsInteractor: TransactionListInteractor,
        balanceInteractor: BalanceListInteractor,
        notificationsInteractor: NotificationsInteractor,
        connectivity: any Connectivity,
        commodityRepository: CommodityCachingRepository,
        seasonRepository: SeasonCatalogueRepository,
        accountId: @escaping () -> String?,
        businessDataContext: BusinessDataContext = .init()
    ) {
        self.businessDataContext = businessDataContext
        self.profileInteractor = profileInteractor
        self.notificationsSettingsInteractor = notificationsSettingsInteractor
        self.transactionsInteractor = transactionsInteractor
        self.balanceInteractor = balanceInteractor
        self.notificationsInteractor = notificationsInteractor
        self.connectivity = connectivity
        self.commodityRepository = commodityRepository
        self.seasonRepository = seasonRepository
        self.accountId = accountId
    }

    // MARK: - DataFetcherInteractor

    /// Fetches all remote data (profile, settings, transactions, balance, notifications)
    func fetchRemoteData() async {
        try? await businessDataContext.withCurrentGeneration {
            startCataloguePreparation()
            async let fetchProfile: Void = profileInteractor.fetchProfile()
            async let fetchSettings: Void = notificationsSettingsInteractor.fetchSettings()
            async let fetchTransactions: Void = transactionsInteractor.refresh(cacheOnly: false)
            async let fetchBalance: Void = balanceInteractor.refresh(cacheOnly: false)
            async let fetchNotifications: Void = connectivity.isReachableFlag
            ? notificationsInteractor.fetchNotifications(notificationTypes: [], refresh: false)
            : ()

            _ = (
                try? await fetchProfile,
                try? await fetchSettings,
                await fetchTransactions,
                await fetchBalance,
                try? await fetchNotifications
            )
        }
    }

    /// Awaits preparation, retaining one follow-up pass for overlapping triggers.
    func prepareCatalogues() async {
        startCataloguePreparation()
        await catalogueTask?.value
    }

    func cancelCataloguePreparation() {
        catalogueGeneration = UUID()
        catalogueTask?.cancel()
        catalogueTask = nil
        hasPendingCatalogueRetry = false
    }

    func startCataloguePreparation() {
        guard let businessGeneration = try? businessDataContext.capture() else { return }

        guard connectivity.isReachableFlag, let participant = accountId(), !participant.isEmpty else { return }
        guard catalogueTask == nil else {
            hasPendingCatalogueRetry = true
            return
        }

        let generation = UUID()
        catalogueGeneration = generation
        catalogueTask = Task {
            await BusinessDataContext.$requestGeneration.withValue(businessGeneration) {
                repeat {
                    guard self.catalogueGeneration == generation, (try? businessGeneration.check()) != nil, self.accountId() == participant else { break }

                    self.hasPendingCatalogueRetry = false
                    await self.prepareCatalogues(participant: participant)
                } while self.catalogueGeneration == generation && self.hasPendingCatalogueRetry && self.connectivity.isReachableFlag
                if self.catalogueGeneration == generation { self.catalogueTask = nil }
            }
        }
    }

    private func prepareCatalogues(participant: String) async {
        do {
            let groups = try await commodityRepository.prepareCatalogue()
            for commodity in groups.flatMap(\.commodities) {
                try Task.checkCancellation()
                guard accountId() == participant else { return }

                do {
                    try await seasonRepository.prepareSeasons(commodityId: commodity.id)
                } catch {
                    if error is CancellationError || Task.isCancelled { return }
                    // Failed snapshots remain missing; continue independent Commodities.
                }
            }
        } catch {
            // Catalogue failure leaves preparation incomplete and safely retryable.
        }
    }

    /// Loads all data from local cache only (offline mode)
    func loadCacheData() async {
        try? await businessDataContext.withCurrentGeneration {
            async let fetchProfile: Void = profileInteractor.fetchProfileFromCache()
            async let fetchTransactions: Void = transactionsInteractor.refresh(cacheOnly: true)
            async let fetchBalance: Void = balanceInteractor.refresh(cacheOnly: true)
            async let fetchNotifications: Void = connectivity.isReachableFlag ? notificationsInteractor.fetchNotificationsFromCache() : ()

            _ = (
                try? await fetchProfile,
                await fetchTransactions,
                await fetchBalance,
                try? await fetchNotifications
            )
        }
    }
}
