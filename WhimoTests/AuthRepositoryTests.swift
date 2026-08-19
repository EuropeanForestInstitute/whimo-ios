//
//  AuthRepositoryTests.swift
//  WhimoTests
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import XCTest
import class Networking.TokenManager
import protocol Networking.TokenManagerProtocol
import RestClient
import Targets
@testable import Whimo

@MainActor
final class AuthRepositoryTests: XCTestCase {
    private var sut: AuthRepository!
    private var authTarget: RecordingAuthTarget!

    override func setUp() {
        super.setUp()

        authTarget = .init()

        guard let authTarget else {
            XCTFail("Test target should be initialized")
            return
        }

        sut = AuthRepositoryImpl(
            authTarget: authTarget,
            tokenManager: TokenManagerTestDouble()
        )
    }

    override func tearDown() {
        authTarget = nil
        sut = nil

        super.tearDown()
    }

    func testEmailRegistrationEncodesEmailWithoutPhone() async throws {
        try await sut.signUp(
            contactIdentifier: .email("participant@example.com"),
            password: "Password1"
        )

        let payload = try registeredPayload()

        XCTAssertEqual(payload["email"] as? String, "participant@example.com")
        XCTAssertEqual(payload["password"] as? String, "Password1")
        XCTAssertNil(payload["phone"])
        XCTAssertEqual(Set(payload.keys), ["email", "password"])
    }

    func testPhoneRegistrationEncodesPhoneWithoutEmail() async throws {
        try await sut.signUp(
            contactIdentifier: .phone("12025551234"),
            password: "Password1"
        )

        let payload = try registeredPayload()

        XCTAssertEqual(payload["phone"] as? String, "12025551234")
        XCTAssertEqual(payload["password"] as? String, "Password1")
        XCTAssertNil(payload["email"])
        XCTAssertEqual(Set(payload.keys), ["password", "phone"])
    }
}

private extension AuthRepositoryTests {
    func registeredPayload() throws -> [String: Any] {
        let model = try XCTUnwrap(authTarget.registeredModel)
        let data = try JSONEncoder().encode(model)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private final class TokenManagerTestDouble: TokenManagerProtocol {
    func updateToken(_ tokens: TokenManager.TokensModel?) {}
}

private final class RecordingAuthTarget: AuthTarget {
    private enum Error: Swift.Error {
        case unusedMethod
    }

    private(set) var registeredModel: RequestModels.Register?

    func register(_ model: RequestModels.Register) async throws {
        registeredModel = model
    }

    func login(_ model: RequestModels.Login) async throws -> ResponseModels.LoginInfo {
        throw Error.unusedMethod
    }

    func googleAuth(_ model: RequestModels.GoogleAuth) async throws -> ResponseModels.LoginInfo {
        throw Error.unusedMethod
    }

    func appleAuth(_ model: RequestModels.AppleAuth) async throws -> ResponseModels.LoginInfo {
        throw Error.unusedMethod
    }

    func sendOTP(_ model: RequestModels.SendOTP) async throws {
        throw Error.unusedMethod
    }

    func verifyOTP(_ model: RequestModels.VerifyOTP) async throws {
        throw Error.unusedMethod
    }

    func sendPasswordReset(_ model: RequestModels.SendOTP) async throws {
        throw Error.unusedMethod
    }

    func checkPasswordReset(_ model: RequestModels.CheckPasswordReset) async throws {
        throw Error.unusedMethod
    }

    func verifyPasswordReset(_ model: RequestModels.VerifyPasswordReset) async throws {
        throw Error.unusedMethod
    }
}
