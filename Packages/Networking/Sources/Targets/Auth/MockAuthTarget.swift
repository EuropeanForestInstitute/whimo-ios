//
//  MockAuthTarget.swift
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

public struct MockAuthTarget: AuthTarget, MockableTarget {
    public func register(_ model: RequestModels.Register) async throws {
        try await sleepRequest()
    }

    public func login(_ model: RequestModels.Login) async throws -> ResponseModels.LoginInfo {
        try await sleepRequest()
        return .mock
    }

    public func sendOTP(_ model: RequestModels.SendOTP) async throws {
        try await sleepRequest()
    }

    public func verifyOTP(_ model: RequestModels.VerifyOTP) async throws {
        try await sleepRequest()
    }

    public func sendPasswordReset(_ model: RequestModels.SendOTP) async throws {
        try await sleepRequest()
    }

    public func checkPasswordReset(_ model: RequestModels.CheckPasswordReset) async throws {
        try await sleepRequest()
    }

    public func verifyPasswordReset(_ model: RequestModels.VerifyPasswordReset) async throws {
        try await sleepRequest()
    }

    public func googleAuth(_ model: RequestModels.GoogleAuth) async throws -> ResponseModels.LoginInfo {
        try await sleepRequest()
        return .mock
    }

    public func appleAuth(_ model: RequestModels.AppleAuth) async throws -> ResponseModels.LoginInfo {
        try await sleepRequest()
        return .mockApple
    }
}

private extension ResponseModels.LoginInfo {
    static var mock: Self {
        .init(
            data: .init(
                access: "access.google.mock.123",
                refresh: "refresh.google.mock.123"
            )
        )
    }

    static var mockApple: Self {
        .init(
            data: .init(
                access: "access.apple.mock.123",
                refresh: "refresh.apple.mock.123"
            )
        )
    }
}
