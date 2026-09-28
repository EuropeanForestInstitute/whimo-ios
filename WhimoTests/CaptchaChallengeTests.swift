//
//  CaptchaChallengeTests.swift
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

import XCTest
@testable import Whimo

final class CaptchaChallengeTests: XCTestCase {
    func testValidSuccessMessageReturnsToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        let effect = session.handleBridgeMessage(
            body: #"{"status":"success","token":"one-use-token"}"#,
            sourceURL: CaptchaConfiguration.formURL
        )

        XCTAssertEqual(effect, .finish(.token("one-use-token")))
    }

    func testKnownRecoverableErrorsKeepChallengeOpenAndAllowLaterSuccess() {
        let sourceURL = CaptchaConfiguration.formURL

        for code in ["script_error", "render_error", "expired"] {
            let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

            XCTAssertEqual(
                session.handleBridgeMessage(
                    body: #"{"status":"error","code":"\#(code)"}"#,
                    sourceURL: sourceURL
                ),
                .noChange
            )
            XCTAssertEqual(
                session.handleBridgeMessage(
                    body: #"{"status":"success","token":"retry-token"}"#,
                    sourceURL: sourceURL
                ),
                .finish(.token("retry-token"))
            )
        }
    }

    func testNavigationFailureFinishesWithoutToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(session.handleNavigationFailure(), .finish(.failure))
    }

    func testNativeCloseCancellationFinishesWithoutToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(session.cancel(), .finish(.cancelled))
    }

    func testMalformedJSONFinishesWithoutToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(
            session.handleBridgeMessage(
                body: "not-json",
                sourceURL: CaptchaConfiguration.formURL
            ),
            .finish(.failure)
        )
    }

    func testUnsafeOutputMapsToModuleFailure() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)
        let effect = session.handleBridgeMessage(
            body: "not-json",
            sourceURL: CaptchaConfiguration.formURL
        )

        XCTAssertEqual(CaptchaChallengeModule.outcome(for: effect), .failure)
    }

    func testUnknownStatusFinishesWithoutToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(
            session.handleBridgeMessage(
                body: #"{"status":"unknown","token":"token"}"#,
                sourceURL: CaptchaConfiguration.formURL
            ),
            .finish(.failure)
        )
    }

    func testEmptyTokenFinishesWithoutToken() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(
            session.handleBridgeMessage(
                body: #"{"status":"success","token":"  \n"}"#,
                sourceURL: CaptchaConfiguration.formURL
            ),
            .finish(.failure)
        )
    }

    func testIncorrectOriginFinishesWithoutToken() throws {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(
            session.handleBridgeMessage(
                body: #"{"status":"success","token":"token"}"#,
                sourceURL: try XCTUnwrap(URL(string: "https://attacker.example"))
            ),
            .finish(.failure)
        )
    }

    func testTopLevelNavigationAllowsOnlyConfiguredOrigin() throws {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertTrue(
            session.allowsTopLevelNavigation(
                to: CaptchaConfiguration.formURL.appendingPathComponent("retry")
            )
        )
        XCTAssertFalse(
            session.allowsTopLevelNavigation(
                to: try XCTUnwrap(URL(string: "https://challenges.cloudflare.com"))
            )
        )
    }

    func testFirstTerminalOutcomeWins() {
        let session = CaptchaChallengeSession(formURL: CaptchaConfiguration.formURL)

        XCTAssertEqual(session.cancel(), .finish(.cancelled))
        XCTAssertEqual(
            session.handleBridgeMessage(
                body: #"{"status":"success","token":"late-token"}"#,
                sourceURL: CaptchaConfiguration.formURL
            ),
            .noChange
        )
    }

    func testConfigurationUsesHostedCaptchaForm() {
        XCTAssertEqual(CaptchaConfiguration.formURL.scheme, "https")
        XCTAssertNotNil(CaptchaConfiguration.formURL.host)
        XCTAssertEqual(CaptchaConfiguration.formURL.path, "/captcha")
    }
}
