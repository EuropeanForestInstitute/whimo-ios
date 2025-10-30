//
//  BalanceCachingRepositoryImpl.swift
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

// MARK: - BalanceCachingRepositoryImpl
final class BalanceCachingRepositoryImpl: BalanceCachingRepository {
    // MARK: - Dependencies
    private let remoteRepository: BalanceRemoteRepository
    private let localRepository: BalanceLocalRepository

    private let commodityLocalRepo: CommodityLocalRepository
    private let commodityRemoteRepo: CommodityRemoteRepository

    // MARK: - Init
    init(
        remoteRepository: BalanceRemoteRepository,
        localRepository: BalanceLocalRepository,
        commodityRemoteRepo: CommodityRemoteRepository,
        commodityLocalRepo: CommodityLocalRepository
    ) {
        self.remoteRepository = remoteRepository
        self.localRepository = localRepository

        self.commodityRemoteRepo = commodityRemoteRepo
        self.commodityLocalRepo = commodityLocalRepo
    }

    // MARK: - BalanceCachingRepository
    func fetchCommodityGroupsBalance() async throws -> IdentifiedArrayOf<CommodityGroupModel> {
        do {
            let remoteGroups = try await commodityRemoteRepo.fetchCommodityGroups()

            for group in remoteGroups {
                try await commodityLocalRepo.save(group)
            }

            let localGroups = try await localRepository.fetchCommodityGroupsBalance()
            return localGroups
        } catch RestClient.RestError.connectionLost {
            let localGroups = try await localRepository.fetchCommodityGroupsBalance()
            return localGroups
        } catch {
            throw error
        }
    }

    func fetchCommodityBalance(commodityId: String) async throws -> IdentifiedArrayOf<CommodityBalanceModel> {
        do {
            let remoteBalances = try await remoteRepository.fetchCommodityBalance(commodityId: commodityId)

            // Save to local storage for offline access
//            try await localRepository.save(remoteBalances)
            return remoteBalances

        } catch RestClient.RestError.connectionLost {
            return []
        } catch {
            throw error
        }
    }
}
