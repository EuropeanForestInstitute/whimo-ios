//
//  AuthRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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
import StorageKit
import class Networking.TokenManager
import RestClient
import Targets

// MARK: - AuthRepositoryImpl
final class AuthRepositoryImpl: AuthRepository {
    // MARK: - Dependencies
    private let authTarget: AuthTarget
    private let tokenManager: TokenManager
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>

    // MARK: - Init
    init(
        authTarget: AuthTarget,
        tokenManager: TokenManager,
        userDefaultsStore: AnyStorage<UserDefaultsStore>
    ) {
        self.authTarget = authTarget
        self.tokenManager = tokenManager
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - AuthRepository
    func signUp(authMethods: Set<AuthMethod>, password: String) async throws {
        var email: String?
        var phone: String?
        for authMethod in authMethods {
            switch authMethod {
                case .email:
                    email = authMethod.identifier
                case .phone:
                    phone = authMethod.identifier
            }
        }

        let request: RequestModels.Register = .init(email: email, phone: phone, password: password)
        try await authTarget.register(request)
    }

    func signIn(authMethod: AuthMethod, password: String) async throws {
        var email: String?
        var phone: String?
        switch authMethod {
            case .email:
                email = authMethod.identifier
            case .phone:
                phone = authMethod.identifier
        }

        let request: RequestModels.Login = .init(username: email ?? phone ?? "", password: password)
        let response = try await authTarget.login(request)
        let tokenData = response.data
        let tokenModel: TokenManager.TokensModel = .init(
            access: tokenData.access,
            refresh: tokenData.refresh
        )
        tokenManager.updateToken(tokenModel)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        let request: RequestModels.AppleAuth = .init(idToken: idToken, nonce: nonce)
        let response = try await authTarget.appleAuth(request)
        let tokenData = response.data
        let tokenModel: TokenManager.TokensModel = .init(
            access: tokenData.access,
            refresh: tokenData.refresh
        )
        tokenManager.updateToken(tokenModel)
    }

    func signInWithGoogle(idToken: String) async throws {
        let request: RequestModels.GoogleAuth = .init(idToken: idToken)
        let response = try await authTarget.googleAuth(request)
        let tokenData = response.data
        let tokenModel: TokenManager.TokensModel = .init(
            access: tokenData.access,
            refresh: tokenData.refresh
        )
        tokenManager.updateToken(tokenModel)
    }

    func sendOTP(gadgetId: String) async throws {
        let request: RequestModels.SendOTP = .init(identifier: gadgetId)
        try await authTarget.sendOTP(request)
    }

    func verifyOTP(gadgetId: String, code: String) async throws {
        let request: RequestModels.VerifyOTP = .init(identifier: gadgetId, code: code)
        try await authTarget.verifyOTP(request)
    }

    func sendPasswordReset(gadgetId: String) async throws {
        let request: RequestModels.SendOTP = .init(identifier: gadgetId)
        try await authTarget.sendPasswordReset(request)
    }

    func checkPasswordReset(gadgetId: String, code: String) async throws {
        let request: RequestModels.CheckPasswordReset = .init(identifier: gadgetId, code: code)
        try await authTarget.checkPasswordReset(request)
    }

    func verifyPasswordReset(gadgetId: String, pass: String, code: String) async throws {
        let request: RequestModels.VerifyPasswordReset = .init(code: code, identifier: gadgetId, password: pass)
        try await authTarget.verifyPasswordReset(request)
    }

    func flush() {
        tokenManager.updateToken(nil)
    }
}
