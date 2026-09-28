//
//  BalancesTarget.swift
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
import Networking
import RestClient

public protocol BalancesTarget {
    func balances(_ request: RequestModels.BalancesList) async throws -> ResponseModels.BalancesInfo
}

public struct RestBalancesTarget: BalancesTarget {
    private let restClient: RestClientProtocol

    public init(restClient: RestClientProtocol) { self.restClient = restClient }

    public func balances(_ request: RequestModels.BalancesList) async throws -> ResponseModels.BalancesInfo {
        try await restClient.makeRequest(RequestRouter.Balances(request: request))
    }
}

extension RequestRouter {
    public struct Balances: AnyNetworkRouter {
        public let request: RequestModels.BalancesList
        public var path: Endpoint { "/commodities/balances/" }
        public var method: HTTPMethod { .get }
        public var parameters: Encodable? { request }
        public var addAuth: Bool { true }

        public init(request: RequestModels.BalancesList) { self.request = request }
    }
}

extension RequestModels {
    public struct BalancesList: Encodable {
        public let search: String
        public let groupId: String?
        public let harvestSeasonId: String?
        public let commodityId: String?
        public let page: Int
        public let pageSize: Int

        private enum CodingKeys: String, CodingKey {
            case search, harvestSeasonId, commodityId, page, pageSize
            case groupId = "commodity_group_id"
        }

        public init(search: String = "", groupId: String? = nil, harvestSeasonId: String? = nil,
                    commodityId: String? = nil, page: Int = 1, pageSize: Int = 20) {
            self.search = search
            self.groupId = groupId
            self.harvestSeasonId = harvestSeasonId
            self.commodityId = commodityId
            self.page = page
            self.pageSize = pageSize
        }
    }
}

extension ResponseModels {
    public struct BalancesInfo: Decodable {
        public let data: [Balance]
        public let pagination: RestClient.Pagination
        public let message: String?
        public let success: Bool?
    }

    public struct Balance: Decodable {
        public let id: String
        public let volume: Double
        public let commodity: Commodity
        public let harvestSeason: HarvestSeason?
        public let traceability: Transaction.Traceability?
        public let hasRecipe: Bool?

        public struct Commodity: Decodable {
            public let id: String
            public let code: String
            public let name: String
            public let unit: String
            public let group: CommodityGroup.Commodity.Group
            public let hasRecipe: Bool?
        }
    }
}
