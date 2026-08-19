//
//  OTPFlowTests.swift
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
import FactoryKit
import CommonUI
import Utility
@testable import Whimo

@MainActor
final class OTPFlowTests: XCTestCase {
    private var appState: AppStateMock!
    private var authRepository: AuthRepositoryMock!

    override func setUp() {
        super.setUp()

        AppContainer.shared.manager.push()
        authRepository = .init()
        guard let authRepository else {
            XCTFail("The auth repository should be initialized")
            return
        }
        let appState = AppStateMock()
        self.appState = appState
        AppContainer.shared.authRepository
            .register { authRepository }
            .scope(.unique)
        AppContainer.shared.appState
            .register { appState }
            .scope(.unique)
    }

    override func tearDown() {
        AppContainer.shared.manager.pop()
        authRepository = nil
        appState = nil

        super.tearDown()
    }

    func testInitialCancellationReturnsToOpeningScreenWithoutSending() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        appState.navigation[\.path] = [
            .root(.login, embedInNavigationView: true),
            .push(.forgotPassword),
            .push(.otp(parrentFlow: .restorePassword, gadgets: .init(gadget)))
        ]
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .restorePassword,
            gadgets: .init(gadget)
        )

        viewModel.didCompleteCaptchaChallenge(.cancelled)
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertEqual(appState.navigation.value.path.count, 2)
        if case .forgotPassword = appState.navigation.value.path.last?.screen {
            // The participant returned to the screen that opened OTP.
        } else {
            XCTFail("Initial captcha cancellation should remove the OTP route")
        }
        XCTAssertTrue(authRepository.sendOTPCalls.isEmpty)
        XCTAssertTrue(authRepository.sendPasswordResetCalls.isEmpty)
    }

    func testInitialChallengeFailureKeepsOTPAndDoesNotSend() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        appState.navigation[\.path] = [
            .root(.login, embedInNavigationView: true),
            .push(.otp(parrentFlow: .manualVerification(), gadgets: .init(gadget)))
        ]
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )

        viewModel.didCompleteCaptchaChallenge(.failure)
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertEqual(appState.navigation.value.path.count, 2)
        XCTAssertTrue(authRepository.sendOTPCalls.isEmpty)
        XCTAssertTrue(authRepository.sendPasswordResetCalls.isEmpty)
    }

    func testActionWhileInitialChallengeIsVisibleCannotReplaceAttempt() async {
        let email = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let phone = UserModel.GadgetModel.unverified(
            identifier: "+996555123456",
            type: .phone
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(email, [phone])
        )

        viewModel.didTapSwitchGadget()
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(viewModel.selectedGadget, email)
        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: email.identifier, captchaToken: "initial-token")]
        )
    }

    func testActionWhileProtectedRequestIsInFlightCannotStartAnotherAttempt() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let requestStarted = expectation(description: "Protected OTP request started")
        authRepository.suspendsSendOTP = true
        authRepository.onSendOTP = {
            requestStarted.fulfill()
        }
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))

        let requestTask = Task {
            _ = await viewModel.didDismissCaptchaChallenge()
        }
        await fulfillment(of: [requestStarted], timeout: 1)

        viewModel.didTapResendCode()

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertEqual(authRepository.sendOTPCalls.count, 1)

        authRepository.completeSendOTP()
        await requestTask.value

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: gadget.identifier, captchaToken: "initial-token")]
        )
    }

    func testAPIFailureDoesNotRetryAndExplicitRetryUsesFreshToken() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        authRepository.sendOTPResults = [
            .failure(AuthRepositoryTestError.requestFailed),
            .success(())
        ]
        appState.navigation[\.path] = [
            .root(.login, embedInNavigationView: true),
            .push(.otp(parrentFlow: .manualVerification(), gadgets: .init(gadget)))
        ]
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )

        viewModel.didCompleteCaptchaChallenge(.token("uncertain-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertEqual(appState.navigation.value.path.count, 2)
        if case .otp = appState.navigation.value.path.last?.screen {
            // An uncertain result keeps the participant on the OTP screen.
        } else {
            XCTFail("API failure should keep the OTP route")
        }
        XCTAssertEqual(
            appState.errorMessages,
            [AuthRepositoryTestError.requestFailed.localizedDescription]
        )
        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: gadget.identifier, captchaToken: "uncertain-token")]
        )

        viewModel.didTapResendCode()

        XCTAssertTrue(viewModel.isCaptchaPresented)
        XCTAssertEqual(authRepository.sendOTPCalls.count, 1)

        viewModel.didCompleteCaptchaChallenge(.token("fresh-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [
                .init(identifier: gadget.identifier, captchaToken: "uncertain-token"),
                .init(identifier: gadget.identifier, captchaToken: "fresh-token")
            ]
        )
    }

    func testInitialVerificationChallengeGatesAndForwardsTokenOnce() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )
        authRepository.onSendOTP = { [weak self, weak viewModel] in
            XCTAssertFalse(viewModel?.isCaptchaPresented ?? true)
            XCTAssertTrue(self?.appState.system.value.isLoading ?? false)
        }

        XCTAssertTrue(viewModel.isCaptchaPresented)
        XCTAssertTrue(authRepository.sendOTPCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)

        viewModel.didCompleteCaptchaChallenge(.token("verification-token"))

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertTrue(authRepository.sendOTPCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)

        await viewModel.didDismissCaptchaChallenge()
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: gadget.identifier, captchaToken: "verification-token")]
        )
        XCTAssertTrue(authRepository.sendPasswordResetCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)
    }

    func testInitialPasswordResetChallengeGatesAndForwardsTokenOnce() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "+996555123456",
            type: .phone
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .restorePassword,
            gadgets: .init(gadget)
        )
        authRepository.onSendPasswordReset = { [weak self, weak viewModel] in
            XCTAssertFalse(viewModel?.isCaptchaPresented ?? true)
            XCTAssertTrue(self?.appState.system.value.isLoading ?? false)
        }

        XCTAssertTrue(viewModel.isCaptchaPresented)
        XCTAssertTrue(authRepository.sendPasswordResetCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)

        viewModel.didCompleteCaptchaChallenge(.token("password-reset-token"))

        XCTAssertFalse(viewModel.isCaptchaPresented)
        XCTAssertTrue(authRepository.sendPasswordResetCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)

        await viewModel.didDismissCaptchaChallenge()
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendPasswordResetCalls,
            [.init(identifier: gadget.identifier, captchaToken: "password-reset-token")]
        )
        XCTAssertTrue(authRepository.sendOTPCalls.isEmpty)
        XCTAssertFalse(appState.system.value.isLoading)
    }

    func testResendRequiresANewChallengeBeforeSendingAgain() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        viewModel.didTapResendCode()

        XCTAssertTrue(viewModel.isCaptchaPresented)
        XCTAssertEqual(authRepository.sendOTPCalls.count, 1)

        viewModel.didCompleteCaptchaChallenge(.token("resend-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [
                .init(identifier: gadget.identifier, captchaToken: "initial-token"),
                .init(identifier: gadget.identifier, captchaToken: "resend-token")
            ]
        )
    }

    func testResendCancellationStaysOnOTPAndSendsNothingNew() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        appState.navigation[\.path] = [
            .root(.login, embedInNavigationView: true),
            .push(.otp(parrentFlow: .manualVerification(), gadgets: .init(gadget)))
        ]
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        viewModel.didTapResendCode()
        viewModel.didCompleteCaptchaChallenge(.cancelled)
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(appState.navigation.value.path.count, 2)
        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: gadget.identifier, captchaToken: "initial-token")]
        )
    }

    func testExplicitAttemptsAfterCancellationAndFailureUseFreshTokens() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        viewModel.didTapResendCode()
        viewModel.didCompleteCaptchaChallenge(.cancelled)
        await viewModel.didDismissCaptchaChallenge()
        viewModel.didTapResendCode()

        XCTAssertTrue(viewModel.isCaptchaPresented)

        viewModel.didCompleteCaptchaChallenge(.token("after-cancellation-token"))
        await viewModel.didDismissCaptchaChallenge()
        viewModel.didTapResendCode()
        viewModel.didCompleteCaptchaChallenge(.failure)
        await viewModel.didDismissCaptchaChallenge()
        viewModel.didTapResendCode()

        XCTAssertTrue(viewModel.isCaptchaPresented)

        viewModel.didCompleteCaptchaChallenge(.token("after-failure-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [
                .init(identifier: gadget.identifier, captchaToken: "initial-token"),
                .init(identifier: gadget.identifier, captchaToken: "after-cancellation-token"),
                .init(identifier: gadget.identifier, captchaToken: "after-failure-token")
            ]
        )
    }

    func testSwitchRequiresChallengeBeforeExistingSendThenSwitchOrdering() async {
        let email = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let phone = UserModel.GadgetModel.unverified(
            identifier: "+996555123456",
            type: .phone
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(email, [phone])
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        viewModel.didTapSwitchGadget()

        XCTAssertTrue(viewModel.isCaptchaPresented)
        XCTAssertEqual(viewModel.selectedGadget, email)
        XCTAssertEqual(authRepository.sendOTPCalls.count, 1)

        viewModel.didCompleteCaptchaChallenge(.token("switch-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [
                .init(identifier: email.identifier, captchaToken: "initial-token"),
                .init(identifier: email.identifier, captchaToken: "switch-token")
            ]
        )
        XCTAssertEqual(viewModel.selectedGadget, phone)
    }

    func testSwitchCancellationStaysOnOTPAndKeepsSelectedGadget() async {
        let email = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let phone = UserModel.GadgetModel.unverified(
            identifier: "+996555123456",
            type: .phone
        )
        appState.navigation[\.path] = [
            .root(.login, embedInNavigationView: true),
            .push(.otp(parrentFlow: .manualVerification(), gadgets: .init(email, [phone])))
        ]
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(email, [phone])
        )
        viewModel.didCompleteCaptchaChallenge(.token("initial-token"))
        await viewModel.didDismissCaptchaChallenge()

        viewModel.didTapSwitchGadget()
        viewModel.didCompleteCaptchaChallenge(.cancelled)
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(appState.navigation.value.path.count, 2)
        XCTAssertEqual(viewModel.selectedGadget, email)
        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: email.identifier, captchaToken: "initial-token")]
        )
    }

    func testOnlyFirstTerminalChallengeOutcomeCanSend() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "participant@example.com",
            type: .email
        )
        let viewModel = OTPModule.ViewModel(
            parrentFlow: .manualVerification(),
            gadgets: .init(gadget)
        )

        viewModel.didCompleteCaptchaChallenge(.token("first-token"))
        viewModel.didCompleteCaptchaChallenge(.token("duplicate-token"))
        viewModel.didCompleteCaptchaChallenge(.cancelled)
        await viewModel.didDismissCaptchaChallenge()
        viewModel.didCompleteCaptchaChallenge(.token("late-token"))
        await viewModel.didDismissCaptchaChallenge()

        XCTAssertEqual(
            authRepository.sendOTPCalls,
            [.init(identifier: gadget.identifier, captchaToken: "first-token")]
        )
    }

}

private final class AuthRepositoryMock: AuthRepository {
    struct ProtectedSend: Equatable {
        let identifier: String
        let captchaToken: String
    }

    private(set) var sendOTPCalls: [ProtectedSend] = []
    private(set) var sendPasswordResetCalls: [ProtectedSend] = []

    var onSendOTP: (() -> Void)?
    var onSendPasswordReset: (() -> Void)?
    var suspendsSendOTP = false
    var sendOTPResults: [Result<Void, Error>] = []

    private var sendOTPContinuation: CheckedContinuation<Void, Error>?

    func signUp(contactIdentifier: ContactIdentifier, password: String) async throws { }

    func signIn(contactIdentifier: ContactIdentifier, password: String) async throws { }

    func signInWithGoogle(idToken: String) async throws { }

    func signInWithApple(idToken: String, nonce: String) async throws { }

    func sendOTP(gadgetId: String, captchaToken: String) async throws {
        sendOTPCalls.append(.init(identifier: gadgetId, captchaToken: captchaToken))
        if suspendsSendOTP {
            try await withCheckedThrowingContinuation { continuation in
                sendOTPContinuation = continuation
                onSendOTP?()
            }
        } else {
            onSendOTP?()
        }
        if !sendOTPResults.isEmpty {
            try sendOTPResults.removeFirst().get()
        }
    }

    func verifyOTP(gadgetId: String, code: String) async throws { }

    func sendPasswordReset(gadgetId: String, captchaToken: String) async throws {
        sendPasswordResetCalls.append(.init(identifier: gadgetId, captchaToken: captchaToken))
        onSendPasswordReset?()
    }

    func checkPasswordReset(gadgetId: String, code: String) async throws { }

    func verifyPasswordReset(gadgetId: String, pass: String, code: String) async throws { }

    func flush() { }

    func completeSendOTP() {
        sendOTPContinuation?.resume()
        sendOTPContinuation = nil
    }
}

private final class AppStateMock: AppState {
    let system: StateStore<SystemState> = .init(inititalValue: .initialState)
    let navigation: StateStore<NavigationState> = .init(inititalValue: .initialState)
    let transactions: StateStore<TransactionsState> = .init(inititalValue: .initialState)
    let balance: StateStore<BalanceState> = .init(inititalValue: .initialState)
    let createTransaction: StateStore<CreateTransactionState> = .init(inititalValue: .initialState)
    let createPassword: StateStore<CreatePasswordState> = .init(inititalValue: .initialState)
    let notifications: StateStore<NotificationsState> = .init(inititalValue: .initialState)
    let notificationsSettings: StateStore<NotificationsSettingsState> = .init(inititalValue: .initialState)
    let profile: StateStore<ProfileState> = .init(inititalValue: .initialState)

    @MainActor private(set) var errorMessages: [String] = []

    func showInfo(message: String, hapticsEnabled: Bool) { }

    @MainActor
    func showInfo(message: String, hapticsEnabled: Bool) async { }

    @MainActor
    func replace(
        old oldToast: ToastValue?,
        new newToast: ToastValue,
        hapticsEnabled: Bool
    ) async -> ToastValue {
        newToast
    }

    func showError(
        message: String,
        button: ToastManager.ToastButton?,
        hapticsEnabled: Bool
    ) { }

    @MainActor
    func showError(
        message: String,
        button: ToastManager.ToastButton?,
        hapticsEnabled: Bool
    ) async {
        errorMessages.append(message)
    }
}

private enum AuthRepositoryTestError: LocalizedError {
    case requestFailed

    var errorDescription: String? {
        "The protected request result is uncertain."
    }
}
