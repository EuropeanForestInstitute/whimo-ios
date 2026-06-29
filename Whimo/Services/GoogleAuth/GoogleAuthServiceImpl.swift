//
//  GoogleAuthServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 09.07.2025.
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
import GoogleSignIn
import Utility

// MARK: - GoogleAuthServiceImpl
final class GoogleAuthServiceImpl: GoogleAuthService {
    private enum Constants {
        static let kGIDSignInErrorCodeCanceled = -5
    }

    // MARK: - AuthCredentials
    struct AuthCredentials {
        let idToken: String
    }

    // MARK: - Dependencies
    private let googleSignIn: GIDSignIn

    // MARK: - Init
    init() {
        self.googleSignIn = .sharedInstance
    }

    // MARK: - GoogleAuthServiceImpl
    @MainActor
    func authorize() async throws -> AuthCredentials {
        guard
            let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows
                .first?
                .rootViewController
        else { throw Error.cannotOpenAuthUI }

        let result: GIDSignInResult
        do {
            result = try await googleSignIn.signIn(withPresenting: presentingViewController)
        } catch {
            log.error("Google Auth Error: \(error). \(error.localizedDescription)")

            let error = error as NSError
            if error.code == Constants.kGIDSignInErrorCodeCanceled {
                throw Error.cancelledByUser
            }

            throw Error.error(error)
        }

        do {
            let googleUser = try await result.user.refreshTokensIfNeeded()

            guard
                let idToken = googleUser.idToken?.tokenString
            else { throw Error.cannotReceiveIdToken }

            let credentials: AuthCredentials = .init(idToken: idToken)
            return credentials
        } catch {
            log.error("Google Auth Error: \(error). \(error.localizedDescription)")
            throw error
        }
    }
}
