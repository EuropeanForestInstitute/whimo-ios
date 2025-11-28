//
//  MockCommodityConversionTarget.swift
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
//  MockCommodityConversionTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 27.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import RestClient

public struct MockCommodityConversionTarget: CommodityConversionTarget, MockableTarget {
    public init() {}

    public func getConversionRules(_ model: RequestModels.GetConversionRules) async throws -> ResponseModels.ConversionRules {
        try await sleepRequest()

        return .init(
            data: [.mock],
            pagination: .init(pageSize: 1, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1)
        )
    }

    public func makeConversion(_ model: RequestModels.MakeConversion) async throws {
        try await sleepRequest()
    }
}

private extension ResponseModels.Rule {
    static let mock: Self = .init(
        id: "342c799c-6b32-4c38-8033-085d18b18b2c",
        name: "Roast coffee [Mock]",
        inputs: [
            .init(
                id: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
                commodity: .init(
                    id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
                    code: "1401",
                    name: "Coffee beans",
                    unit: "kgs",
                    balance: nil,
                    group: .init(id: "1", name: "123"),
                    hasRecipe: false
                ),
                quantity: 10.0
            )
        ],
        outputs: [
            .init(
                id: "26283af0-17da-4c96-8331-dfb372822f87",
                commodity: .init(
                    id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
                    code: "3298",
                    name: "Roated beans",
                    unit: "buckets",
                    balance: nil,
                    group: .init(id: "1", name: "123"),
                    hasRecipe: false
                ),
                quantity: 5.0
            )
        ]
    )
}
