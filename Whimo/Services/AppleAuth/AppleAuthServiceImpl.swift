//
//  AppleAuthServiceImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 10.09.2025.
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
import AuthenticationServices
import Utility
import CryptoKit

// MARK: - AppleAuthServiceImpl
final class AppleAuthServiceImpl: NSObject, AppleAuthService {
    // MARK: - AuthCredentials
    struct AuthCredentials {
        let idToken: String
        let nonce: String
    }

    // MARK: - Private Properties
    private var lastNonce: String?
    private var continuation: CheckedContinuation<AuthCredentials, Swift.Error>?

    // MARK: - AppleAuthService
    func authorize() async throws -> AuthCredentials {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let nonce = randomNonceString()
            let encodedNonce = sha256(nonce)
            self.lastNonce = encodedNonce

            let provider: ASAuthorizationAppleIDProvider = .init()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = encodedNonce

            let controller: ASAuthorizationController = .init(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - Private Methods
private extension AppleAuthServiceImpl {
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    func handleAuthorizationSuccess(_ authorization: ASAuthorization) {
        log.debug()

        switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let nonce = self.lastNonce else {
                    self.continuation?.resume(throwing: Error.loginNotRequested)
                    return
                }

                guard let idToken = appleIDCredential.identityToken else {
                    self.continuation?.resume(throwing: Error.cannotReceiveIdToken)
                    return
                }

                guard let idTokenString: String = .init(data: idToken, encoding: .utf8) else {
                    self.continuation?.resume(throwing: Error.cannotSerializeIdToken)
                    return
                }

                let credentials: AuthCredentials = .init(idToken: idTokenString, nonce: nonce)
                self.continuation?.resume(returning: credentials)
            default:
                self.continuation?.resume(throwing: Error.unsupportedCredentials)
        }
    }

    func handleAuthorizationFailure(_ error: any Swift.Error) {
        log.error(error.localizedDescription)
        switch error {
            case let error as ASAuthorizationError where error.code == ASAuthorizationError.Code.canceled:
                self.continuation?.resume(throwing: Error.cancelledByUser)
            default:
                self.continuation?.resume(throwing: Error.error(error))
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleAuthServiceImpl: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAuthorizationSuccess(authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Swift.Error) {
        handleAuthorizationFailure(error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthServiceImpl: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard
            let topWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows
            .first
        else { fatalError("Unable to present authorization request.") }

        return topWindow
    }
}
