//
//  CommoditiesTarget.swift
//  Whimo
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
//
//  CommoditiesTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 28.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Networking
import RestClient

public protocol CommoditiesTarget {
    func commoditiesList(_ model: RequestModels.CommoditiesList) async throws -> ResponseModels.CommodityInfo
    func commodityGroupsList(_ model: RequestModels.CommodityGroupsList) async throws -> ResponseModels.CommodityGroupInfo
    func commoditiesBalancesList(_ model: RequestModels.CommoditiesBalancesList) async throws -> ResponseModels.CommodityBalanceInfo
}

extension RequestRouter {
    public enum Commodities {
        case commoditiesList(RequestModels.CommoditiesList)
        case commodityGroupsList(RequestModels.CommodityGroupsList)
        case commoditiesBalancesList(RequestModels.CommoditiesBalancesList)
    }
}

extension RequestRouter.Commodities: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .commoditiesList:
                "/commodities/"
            case .commodityGroupsList:
                "/commodities/groups/"
            case .commoditiesBalancesList:
                "/commodities/balances/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .commoditiesList:
                .get
            case .commodityGroupsList:
                .get
            case .commoditiesBalancesList:
                .get
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .commoditiesList(let data):
                data
            case .commodityGroupsList(let data):
                data
            case .commoditiesBalancesList(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .commoditiesList, .commodityGroupsList, .commoditiesBalancesList:
                return true
        }
    }
}
