//
//  SeasonCatalogueRepositoryImpl.swift
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
import DatabaseKit
import RestClient
import Targets

final class SeasonCatalogueRepositoryImpl: SeasonCatalogueRepository {
    private let businessDataContext: BusinessDataContext
    private let groupsTarget: CommoditiesTarget
    private let seasonsTarget: HarvestSeasonsTarget
    private let database: DatabaseKit.Database
    private let mapper: SeasonCatalogueMapperProtocol
    private let accountId: () -> String?

    init(groupsTarget: CommoditiesTarget, seasonsTarget: HarvestSeasonsTarget,
         database: DatabaseKit.Database, mapper: SeasonCatalogueMapperProtocol, accountId: @escaping () -> String?,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.groupsTarget = groupsTarget
        self.seasonsTarget = seasonsTarget
        self.database = database
        self.mapper = mapper
        self.accountId = accountId
    }

    func cachedSeasons(commodityId: String) async throws -> [HarvestSeason] {
        try await businessDataContext.withCurrentGeneration {
            let businessGeneration = try businessDataContext.capture()
            let participant = try participantId()
            let saved = try await database.readOne(SeasonCatalogueCache.filter(key: "commodity:" + commodityId))
            try businessGeneration.check()
            try validateSession(participant)
            guard let saved else { return [] }

            return try JSONDecoder().decode([HarvestSeason].self, from: saved.payload)
        }
    }

    func prepareSeasons(commodityId: String) async throws {
        try await businessDataContext.withCurrentGeneration {
            let businessGeneration = try businessDataContext.capture()
            let participant = try participantId()
            let saved = try await database.readOne(SeasonCatalogueCache.filter(key: "commodity:" + commodityId))
            try businessGeneration.check()
            try validateSession(participant)
            if let saved {
                _ = try JSONDecoder().decode([HarvestSeason].self, from: saved.payload)
                return
            }
            _ = try await seasons(key: "commodity:" + commodityId, groupId: nil, commodityId: commodityId, onlyIfMissing: true)
        }
    }

    func groups() async throws -> CatalogueResult<CatalogueGroup> {
        try await businessDataContext.withCurrentGeneration {
            try await load(key: "groups") {
                var groups: [CatalogueGroup] = []
                var pagination = CataloguePagination()
                while true {
                    let response = try await self.groupsTarget.commodityGroupsList(.init(pageData: .init(page: pagination.page, pageSize: 100)))
                    groups += response.data.map(self.mapper.toDomain)
                    try businessDataContext.capture().check()
                    guard try pagination.advance(response.pagination, itemCount: response.data.count) else { break }

                }
                return groups
            }
        }
    }

    func seasons(groupId: String) async throws -> CatalogueResult<HarvestSeason> {
        try await businessDataContext.withCurrentGeneration {
            try await seasons(key: "group:" + groupId, groupId: groupId, commodityId: nil)
        }
    }

    func seasons(commodityId: String) async throws -> CatalogueResult<HarvestSeason> {
        try await businessDataContext.withCurrentGeneration {
            try await seasons(key: "commodity:" + commodityId, groupId: nil, commodityId: commodityId)
        }
    }

    private func seasons(key: String, groupId: String?, commodityId: String?,
                         onlyIfMissing: Bool = false) async throws -> CatalogueResult<HarvestSeason> {
        try await load(key: key, onlyIfMissing: onlyIfMissing) {
            var seasons: [HarvestSeason] = []
            var pagination = CataloguePagination()
            while true {
                let response = try await self.seasonsTarget.seasons(.init(commodityGroupId: groupId, commodityId: commodityId, page: pagination.page))
                seasons += try response.data.map(self.mapper.toDomain)
                try businessDataContext.capture().check()
                guard try pagination.advance(response.pagination, itemCount: response.data.count) else { break }

            }
            guard seasons.allSatisfy({ !$0.id.isEmpty }), Set(seasons.map(\.id)).count == seasons.count else {
                throw CocoaError(.coderInvalidValue)
            }
            return seasons
        }
    }

    private func load<Value: Codable>(key: String, onlyIfMissing: Bool = false,
                                      fetch: () async throws -> [Value]) async throws -> CatalogueResult<Value> {
        let businessGeneration = try businessDataContext.capture()
        let participant = try participantId()
        do {
            let values = try await fetch()
            try businessGeneration.check()
            try validateSession(participant)
            let record = SeasonCatalogueCache(id: key, payload: try JSONEncoder().encode(values))
            try await database.save { [accountId] db in
                try businessGeneration.whileCurrent {
                    guard accountId() == participant else { throw CancellationError() }

                    // An ordinary creation refresh may have completed while preparation was pending.
                    if onlyIfMissing, try SeasonCatalogueCache.fetchOne(db, key: key) != nil { return }

                    try record.save(db)
                }
            }
            try businessGeneration.check()
            try validateSession(participant)
            return .init(values: values, isCached: false)
        } catch RestClient.RestError.connectionLost {
            try businessGeneration.check()
            try validateSession(participant)
            guard let record = try await database.readOne(SeasonCatalogueCache.filter(key: key)) else {
                throw RestClient.RestError.connectionLost
            }
            try businessGeneration.check()
            try validateSession(participant)
            return .init(values: try JSONDecoder().decode([Value].self, from: record.payload), isCached: true)
        }
    }

    private func participantId() throws -> String {
        guard let participant = accountId(), !participant.isEmpty else { throw CancellationError() }

        return participant
    }

    private func validateSession(_ participant: String) throws {
        try businessDataContext.capture().check()
        guard accountId() == participant else { throw CancellationError() }

    }
}
