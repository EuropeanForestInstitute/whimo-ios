//
//  MockUsersTarget.swift
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
import RestClient

public struct MockUsersTarget: UsersTarget, MockableTarget {
    public init() {}

    public func getProfileInfo() async throws -> ResponseModels.ProfileInfo {
        try await sleepRequest()

        return .init(
            data: .init(
                id: "e3e70682-c209-4cac-a29f-6fbed82c07cd",
                username: "john",
                gadgets: [
                    .init(
                        id: "123",
                        identifier: "john@example.com",
                        type: .email,
                        isVerified: true
                    ),
                    .init(
                        id: "456",
                        identifier: "1234567890",
                        type: .phone,
                        isVerified: false
                    ),
                ]
            )
        )
    }

    public func changePassword(_ model: RequestModels.ChangePassword) async throws {
        try await sleepRequest()
    }

    public func deleteProfile() async throws {
        try await sleepRequest()
    }

    public func checkGadgetExists(_ model: RequestModels.CheckGadgetExists) async throws -> ResponseModels.CheckGadgetExistsInfo {
        try await sleepRequest()

        return .init(data: .init(exists: false))
    }

    public func addGadget(_ model: RequestModels.AddGadget) async throws {
        try await sleepRequest()
    }

    public func deleteGadget(_ model: RequestModels.DeleteGadget) async throws {
        try await sleepRequest()
    }
}
