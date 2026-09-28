//
//  CommodityCachingRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 19.06.2025.
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
import RestClient
import Utility

// MARK: - CommodityCachingRepositoryImpl
final class CommodityCachingRepositoryImpl: CommodityCachingRepository {
    // MARK: - Dependencies
    private let businessDataContext: BusinessDataContext
    private let localRepo: CommodityLocalRepository
    private let remoteRepo: CommodityRemoteRepository
    private let accountId: () -> String?

    // MARK: - Init
    init(localRepo: CommodityLocalRepository, remoteRepo: CommodityRemoteRepository, accountId: @escaping () -> String?,
         businessDataContext: BusinessDataContext = .init()) {
        self.businessDataContext = businessDataContext
        self.localRepo = localRepo
        self.remoteRepo = remoteRepo
        self.accountId = accountId
    }

    // MARK: - CommodityCachingRepository
    func prepareCatalogue() async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        try await businessDataContext.withCurrentGeneration {
            let participant = try participantId()
            if let saved = try await localRepo.preparedCatalogue() {
                try validateSession(participant)
                return saved
            }
            return try await fetchAndSave(participant: participant)
        }
    }

    func fetchCommodityGroups() async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        try await businessDataContext.withCurrentGeneration {
            let participant = try participantId()
            do {
                return try await fetchAndSave(participant: participant)
            } catch RestClient.RestError.connectionLost {
                try validateSession(participant)
                let groups = try await localRepo.fetchCommodityGroups()
                try validateSession(participant)
                return groups
            }
        }
    }

    private func fetchAndSave(participant: String) async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        let groups = try await remoteRepo.fetchCommodityGroups()
        try validateSession(participant)
        let businessGeneration = try businessDataContext.capture()
        try await localRepo.saveCatalogue(groups) { [accountId] in
            try businessGeneration.check()
            guard accountId() == participant else { throw CancellationError() }

        }
        try validateSession(participant)
        return groups
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
