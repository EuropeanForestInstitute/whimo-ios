//
//  CommoditySeasonFilterViewModel.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 19.08.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import Combine

@MainActor
final class CommoditySeasonFilterViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let applied: CommoditySeasonFilter
    @Published private(set) var draft: CommoditySeasonFilter
    @Published private(set) var groups: [CatalogueGroup] = []
    @Published private(set) var seasons: [HarvestSeason] = []
    @Published private(set) var groupsLoading = false
    @Published private(set) var seasonsLoading = false
    @Published private(set) var groupsFailed = false
    @Published private(set) var seasonsFailed = false
    @Published private(set) var groupsCached = false
    @Published private(set) var seasonsCached = false

    private let catalogue: SeasonCatalogueInteractor
    private let onApply: (CommoditySeasonFilter) -> Void
    private var generation = UUID()

    init(applied: CommoditySeasonFilter, catalogue: SeasonCatalogueInteractor,
         onApply: @escaping (CommoditySeasonFilter) -> Void) {
        self.applied = applied
        self.draft = applied
        self.catalogue = catalogue
        self.onApply = onApply
    }

    var canReset: Bool { !draft.isEmpty }
    var canApply: Bool { draft != applied }

    func load() async {
        await loadGroups()
    }

    func loadGroups() async {
        groupsLoading = true
        groupsFailed = false
        defer { groupsLoading = false }
        do {
            let result = try await catalogue.groups()
            groups = result.values
            groupsCached = result.isCached
        } catch {
            groupsFailed = true
        }
    }

    func selectGroup(_ group: CatalogueGroup?) {
        guard draft.group?.id != group?.id else { return }

        draft.selectGroup(group)
        clearSeasons()
    }

    func selectSeason(_ season: HarvestSeason?) {
        guard season == nil || seasons.contains(where: { $0.id == season?.id }) else { return }

        draft.selectSeason(season)
    }

    func reset() {
        draft = .init()
        clearSeasons()
    }

    func apply() {
        guard canApply else { return }

        onApply(draft)
    }

    func cancelLoading() {
        generation = UUID()
    }

    private func clearSeasons() {
        cancelLoading()
        seasons = []
        seasonsFailed = false
        seasonsCached = false
        seasonsLoading = false
    }

    func loadSeasons() async {
        clearSeasons()
        guard let groupId = draft.group?.id else { return }

        let token = generation
        seasonsLoading = true
        do {
            let result = try await catalogue.seasons(groupId: groupId)
            guard generation == token else { return }

            seasons = result.values
            seasonsCached = result.isCached
            seasonsLoading = false
        } catch {
            guard generation == token else { return }

            seasonsFailed = true
            seasonsLoading = false
        }
    }
}
