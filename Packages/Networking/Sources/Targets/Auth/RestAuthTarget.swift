//
//  RestAuthTarget.swift
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
//  RestAuthTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 05.05.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Networking
import RestClient

public struct RestAuthTarget: AnyNetworkTarget {
    public let restClient: any RestClientProtocol

    public init(restClient: any RestClientProtocol) {
        self.restClient = restClient
    }
}

extension RestAuthTarget: AuthTarget {
    public func register(_ model: RequestModels.Register) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.register(model))
    }

    public func login(_ model: RequestModels.Login) async throws -> ResponseModels.LoginInfo {
        try await restClient.makeRequest(RequestRouter.Auth.login(model))
    }

    public func sendOTP(_ model: RequestModels.SendOTP) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.sendOTP(model))
    }

    public func verifyOTP(_ model: RequestModels.VerifyOTP) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.verifyOTP(model))
    }

    public func sendPasswordReset(_ model: RequestModels.SendOTP) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.sendPasswordReset(model))
    }

    public func checkPasswordReset(_ model: RequestModels.CheckPasswordReset) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.checkPasswordReset(model))
    }

    public func verifyPasswordReset(_ model: RequestModels.VerifyPasswordReset) async throws {
        let _: VoidResponse = try await restClient.makeRequest(RequestRouter.Auth.verifyPasswordReset(model))
    }

    public func googleAuth(_ model: RequestModels.GoogleAuth) async throws -> ResponseModels.LoginInfo {
        try await restClient.makeRequest(RequestRouter.Auth.googleAuth(model))
    }

    public func appleAuth(_ model: RequestModels.AppleAuth) async throws -> ResponseModels.LoginInfo {
        try await restClient.makeRequest(RequestRouter.Auth.appleAuth(model))
    }
}
