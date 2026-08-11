//
//  AuthInteractorImpl.swift
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
import Networking
import RestClient
import StorageKit

// MARK: - AuthInteractorImpl
final class AuthInteractorImpl: AuthInteractor {
    // MARK: - SignInResult
    enum SignInResult {
        case verifyGadget
        case success(user: UserModel)
    }

    // MARK: - Dependencies
    private let appState: AppState
    private let authRepository: AuthRepository
    private let appleAuthService: AppleAuthService
    private let googleAuthService: GoogleAuthService
    private let profileRepository: ProfileCachingRepository
    private let userDefaultsStore: AnyStorage<UserDefaultsStore>

    // MARK: - Init
    init(
        appState: AppState,
        authRepository: AuthRepository,
        appleAuthService: AppleAuthService,
        googleAuthService: GoogleAuthService,
        profileRepository: ProfileCachingRepository,
        userDefaultsStore: AnyStorage<UserDefaultsStore>
    ) {
        self.appState = appState
        self.authRepository = authRepository
        self.appleAuthService = appleAuthService
        self.googleAuthService = googleAuthService
        self.profileRepository = profileRepository
        self.userDefaultsStore = userDefaultsStore
    }

    // MARK: - AuthInteractor
    func signUp(contactIdentifier: ContactIdentifier, password: String) async throws {
        try await authRepository.signUp(contactIdentifier: contactIdentifier, password: password)
    }

    func signIn(contactIdentifier: ContactIdentifier, password: String) async throws -> SignInResult {
        do {
            try await authRepository.signIn(contactIdentifier: contactIdentifier, password: password)
            userDefaultsStore.set(true, key: .isLoggedIn)
        } catch RestClient.RestError.clientError(_, let code) where code == .forbidden {
            return .verifyGadget
        } catch {
            throw error
        }

        let userModel = try await profileRepository.fetchProfile()
        return .success(user: userModel)
    }

    func signInWithApple() async throws -> UserModel {
        let credentials = try await appleAuthService.authorize()

        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        try await authRepository.signInWithApple(idToken: credentials.idToken, nonce: credentials.nonce)
        userDefaultsStore.set(true, key: .isLoggedIn)

        let userModel = try await profileRepository.fetchProfile()

        return userModel
    }

    func signInWithGoogle() async throws -> UserModel {
        let credentials = try await googleAuthService.authorize()

        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        try await authRepository.signInWithGoogle(idToken: credentials.idToken)
        userDefaultsStore.set(true, key: .isLoggedIn)

        let userModel = try await profileRepository.fetchProfile()

        return userModel
    }

    func deleteAccount() async throws {
        try await profileRepository.deleteProfile()
    }
}
