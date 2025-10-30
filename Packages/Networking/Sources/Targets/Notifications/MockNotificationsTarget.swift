//
//  MockNotificationsTarget.swift
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
//  MockNotificationsTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 24.06.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import RestClient

public struct MockNotificationsTarget: NotificationsTarget, MockableTarget {
    public func notificationsList(_ model: RequestModels.NotificationsList) async throws -> ResponseModels.NotificationsList {
        try await sleepRequest()

        return .init(
            data: [.mock],
            pagination: .init(pageSize: 1, nextPage: nil, previousPage: nil, count: 1, totalPages: 1, page: 1)
        )
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

private extension ResponseModels.Notification {
    static let mock: Self = .init(
        id: "0cf37e60-002d-40a6-b498-1dac41b7f41a",
        data: .init(
            transaction: .init(
                id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                createdAt: "2025-05-27T11:17:35.614Z",
                expiresAt: nil,
                updatedAt: "2025-05-27T11:17:35.614Z",
                type: .producer,
                status: .accepted,
                action: .buy,
                traceability: .fullTraceability,
                location: .qrCode,
                farmLatitude: 0.1,
                farmLongitude: 0.1,
                transactionLatitude: nil,
                transactionLongitude: nil,
                commodity: .mock,
                volume: 300,
                isBuyingFromFarmer: false,
                isAutomatic: false,
                seller: nil,
                buyer: .init(
                    id: "c3a55629-7b32-4e42-afdc-abcec85e1815",
                    username: "natural-misty-lion-894e80",
                    gadgets: [
                        .init(
                            id: "d2a63cb0-81ba-4722-8577-b785f8a610c4",
                            identifier: "test.email@gmail.com",
                            type: .email,
                            isVerified: true
                        )
                    ]
                ),
                createdById: "c3a55629-7b32-4e42-afdc-abcec85e1815"
            )
        ),
        createdAt: "2025-06-23T15:11:31.881402Z",
        type: .transactionAccepted,
        status: .pending
    )
}
