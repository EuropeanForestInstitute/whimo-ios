//
//  CommodityConversionTarget.swift
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

import Foundation
import Networking
import Alamofire
import RestClient

public protocol CommodityConversionTarget {
    func getConversionRules(_ model: RequestModels.GetConversionRules) async throws -> ResponseModels.ConversionRules
    func makeConversion(_ model: RequestModels.MakeConversion) async throws
}

extension RequestRouter {
    // MARK: - CommodityConversion
    public enum CommodityConversion {
        case getConversionRules(RequestModels.GetConversionRules)
        case makeConversion(RequestModels.MakeConversion)
    }
}

// MARK: - RequestRouter+CommodityConversion
extension RequestRouter.CommodityConversion: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .getConversionRules:
                "/transactions/conversion/"
            case .makeConversion:
                "/transactions/conversion/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .getConversionRules:
                .get
            case .makeConversion:
                .post
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .getConversionRules(let data):
                data
            case .makeConversion(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .getConversionRules:
                true
            case .makeConversion:
                true
        }
    }
}
