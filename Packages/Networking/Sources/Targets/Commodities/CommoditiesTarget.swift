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
    func commodityGroupsList(_ model: RequestModels.CommodityGroupsList) async throws -> ResponseModels.CommodityGroupInfo
}

extension RequestRouter {
    public enum Commodities {
        case commodityGroupsList(RequestModels.CommodityGroupsList)
    }
}

extension RequestRouter.Commodities: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .commodityGroupsList:
                "/commodities/groups/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .commodityGroupsList:
                .get
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .commodityGroupsList(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .commodityGroupsList:
                return true
        }
    }
}
