//
//  HarvestSeasonsTarget.swift
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
import Alamofire
import Networking
import RestClient

public protocol HarvestSeasonsTarget {
    func seasons(_ request: RequestModels.HarvestSeasonsList) async throws -> ResponseModels.HarvestSeasonsInfo
}

public struct RestHarvestSeasonsTarget: HarvestSeasonsTarget {
    private let restClient: RestClientProtocol

    public init(restClient: RestClientProtocol) {
        self.restClient = restClient
    }

    public func seasons(_ request: RequestModels.HarvestSeasonsList) async throws -> ResponseModels.HarvestSeasonsInfo {
        try await restClient.makeRequest(RequestRouter.HarvestSeasons(request: request))
    }
}

extension RequestRouter {
    public struct HarvestSeasons: AnyNetworkRouter {
        public let request: RequestModels.HarvestSeasonsList
        public var path: Endpoint { "/harvest-seasons/" }
        public var method: HTTPMethod { .get }
        public var parameters: Encodable? { request }
        public var addAuth: Bool { true }
        public var encoder: ParameterEncoding { URLEncoding(arrayEncoding: .noBrackets) }

        public init(request: RequestModels.HarvestSeasonsList) {
            self.request = request
        }
    }
}

extension RequestModels {
    public struct HarvestSeasonsList: Encodable {
        public let commodityGroupId: String?
        public let commodityId: String?
        public let commodityIds: [String]?
        public let page: Int
        public let pageSize: Int

        public init(commodityGroupId: String? = nil, commodityId: String? = nil, page: Int = 1, pageSize: Int = 100) {
            self.commodityGroupId = commodityGroupId
            self.commodityId = commodityId
            self.commodityIds = nil
            self.page = page
            self.pageSize = pageSize
        }

        public init(commodityIds: [String], page: Int = 1, pageSize: Int = 100) {
            self.commodityGroupId = nil
            self.commodityId = nil
            self.commodityIds = commodityIds
            self.page = page
            self.pageSize = pageSize
        }

        private enum CodingKeys: String, CodingKey {
            case commodityGroupId, commodityId, page, pageSize
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(commodityGroupId, forKey: .commodityGroupId)
            if let commodityIds {
                try container.encode(commodityIds, forKey: .commodityId)
            } else {
                try container.encodeIfPresent(commodityId, forKey: .commodityId)
            }
            try container.encode(page, forKey: .page)
            try container.encode(pageSize, forKey: .pageSize)
        }
    }
}

extension ResponseModels {
    public struct HarvestSeasonsInfo: AnyPaginationDataResponse {
        public let data: [HarvestSeason]
        public let pagination: Pagination

        public init(data: [HarvestSeason], pagination: Pagination) {
            self.data = data
            self.pagination = pagination
        }
    }

    public struct HarvestSeason: Codable, Equatable {
        public let id: String
        public let name: String
        public let startDate: String
        public let endDate: String
        public let status: Status

        public enum Status: String, Codable {
            case active
            case past
            case archived
        }

        public init(id: String, name: String, startDate: String, endDate: String, status: Status) {
            self.id = id
            self.name = name
            self.startDate = startDate
            self.endDate = endDate
            self.status = status
        }
    }
}
