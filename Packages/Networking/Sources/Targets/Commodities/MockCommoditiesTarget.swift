//
//  MockCommoditiesTarget.swift
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
//  MockCommoditiesTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 28.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import RestClient

public struct MockCommoditiesTarget: CommoditiesTarget, MockableTarget {
    public func commoditiesList(_ model: RequestModels.CommoditiesList) async throws -> ResponseModels.CommodityInfo {
        try await sleepRequest()

        return .init(data: [.mock])
    }

    public func commodityGroupsList(_ model: RequestModels.CommodityGroupsList) async throws -> ResponseModels.CommodityGroupInfo {
        try await sleepRequest()

        return .init(data: [.mock])
    }

    public func commoditiesBalancesList(_ model: RequestModels.CommoditiesBalancesList) async throws -> ResponseModels.CommodityBalanceInfo {
        try await sleepRequest()

        return .init(data: [])
    }
}

private extension ResponseModels.Commodity {
    static let mock: Self = .init(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        code: "1801",
        name: "Cocoa beans, whole or broken, raw or roasted",
        unit: "kg",
        group: .init(
            id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            name: "Cocoa"
        )
    )
}

private extension ResponseModels.CommodityGroup {
    static let mock: Self = .init(
        id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        name: "Cocoa",
        commodities: [
            .init(
                id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                code: "1801",
                name: "Cocoa beans, whole or broken, raw or roasted",
                unit: "kg",
                balance: nil
            )
        ]
    )
}

private extension ResponseModels.CommodityBalance {
    static let mock: Self = .init(
        id: "71396c3c-1968-46cb-a772-f1ba7d6a91f6",
        volume: 200,
        commodity: .init(
            id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
            code: "1401",
            name: "Coffee beans",
            unit: "kgs",
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        )
    )
}
