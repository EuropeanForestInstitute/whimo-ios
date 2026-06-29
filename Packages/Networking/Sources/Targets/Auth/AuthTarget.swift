//
//  AuthTarget.swift
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
import RestClient

public protocol AuthTarget {
    func register(_ model: RequestModels.Register) async throws
    func login(_ model: RequestModels.Login) async throws -> ResponseModels.LoginInfo
    func googleAuth(_ model: RequestModels.GoogleAuth) async throws -> ResponseModels.LoginInfo
    func appleAuth(_ model: RequestModels.AppleAuth) async throws -> ResponseModels.LoginInfo
    func sendOTP(_ model: RequestModels.SendOTP) async throws
    func verifyOTP(_ model: RequestModels.VerifyOTP) async throws
    func sendPasswordReset(_ model: RequestModels.SendOTP) async throws
    func checkPasswordReset(_ model: RequestModels.CheckPasswordReset) async throws
    func verifyPasswordReset(_ model: RequestModels.VerifyPasswordReset) async throws
}

extension RequestRouter {
    public enum Auth {
        case register(_ model: RequestModels.Register)
        case login(_ model: RequestModels.Login)
        case googleAuth(_ model: RequestModels.GoogleAuth)
        case appleAuth(_ model: RequestModels.AppleAuth)

        case sendOTP(_ model: RequestModels.SendOTP)
        case verifyOTP(_ model: RequestModels.VerifyOTP)

        case sendPasswordReset(_ model: RequestModels.SendOTP)
        case checkPasswordReset(_ model: RequestModels.CheckPasswordReset)
        case verifyPasswordReset(_ model: RequestModels.VerifyPasswordReset)
    }
}

extension RequestRouter.Auth: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .register:
                "/auth/registration/"
            case .login:
                "/auth/jwt/"
            case .googleAuth:
                "/auth/social/google/login/"
            case .appleAuth:
                "/auth/social/apple/login/"
            case .sendOTP:
                "/auth/otp/send/"
            case .verifyOTP:
                "/auth/otp/verify/"
            case .sendPasswordReset:
                "/auth/otp/password-reset/send/"
            case .checkPasswordReset:
                "/auth/otp/password-reset/check/"
            case .verifyPasswordReset:
                "/auth/otp/password-reset/verify/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .register:
                .post
            case .login:
                .post
            case .googleAuth:
                .post
            case .appleAuth:
                .post
            case .sendOTP:
                .post
            case .verifyOTP:
                .post
            case .sendPasswordReset:
                .post
            case .checkPasswordReset:
                .post
            case .verifyPasswordReset:
                .post
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .register(let data):
                data
            case .login(let data):
                data
            case .googleAuth(let data):
                data
            case .appleAuth(let data):
                data
            case .sendOTP(let data):
                data
            case .verifyOTP(let data):
                data
            case .sendPasswordReset(let data):
                data
            case .checkPasswordReset(let data):
                data
            case .verifyPasswordReset(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .register:
                false
            case .login:
                false
            case .googleAuth:
                false
            case .appleAuth:
                false
            case .sendOTP:
                false
            case .verifyOTP:
                false
            case .sendPasswordReset:
                false
            case .checkPasswordReset:
                false
            case .verifyPasswordReset:
                false
        }
    }
}
