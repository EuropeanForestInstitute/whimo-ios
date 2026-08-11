//
//  RegisterViewModelTests.swift
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
import Combine
import XCTest
import FactoryKit
import class CommonUI.ToastManager
@testable import Whimo

@MainActor
final class RegisterViewModelTests: XCTestCase {
    private var appState: RegisterAppStateTestDouble!
    private var authInteractor: RegisterAuthInteractorTestDouble!

    override func setUp() {
        super.setUp()

        AppContainer.shared.manager.push()
        appState = .init()
        authInteractor = .init()

        guard let appState, let authInteractor else {
            XCTFail("Test dependencies should be initialized")
            return
        }

        AppContainer.shared.appState
            .register { appState }
            .scope(.unique)
        AppContainer.shared.authInteractor
            .register { authInteractor }
            .scope(.unique)
        AppContainer.shared.remoteConfigService
            .register { RegisterRemoteConfigServiceTestDouble.supportingUnitedStates }
            .scope(.unique)
        AppContainer.shared.tokenRegistryService
            .register { RegisterTokenRegistryServiceTestDouble() }
            .scope(.unique)
    }

    override func tearDown() {
        AppContainer.shared.manager.pop()
        authInteractor = nil
        appState = nil

        super.tearDown()
    }

    func testFormStartsWithEmailSelectedBeforePhone() {
        let viewModel = RegisterModule.ViewModel()

        XCTAssertEqual(viewModel.selectedContactIdentifierType, .email)
        XCTAssertEqual(viewModel.contactIdentifierTypes.elements, [.email, .phone])
    }

    func testSwitchingSegmentsPreservesDraftsAndClearsHiddenIdentifierValidation() async {
        let viewModel = RegisterModule.ViewModel()
        viewModel.credentials = .init(
            email: "invalid-email",
            phone: "+1 202 555 1234",
            password: "Password1",
            repeatPassword: "Password1",
            isTermsAccepted: true
        )
        viewModel.setKeyboardActiveField(.email)
        viewModel.credentials.email = "still-invalid"
        await drainMainQueue()

        XCTAssertNotNil(viewModel.validationErrors[.email])

        viewModel.selectContactIdentifierType(.phone)

        XCTAssertEqual(viewModel.selectedContactIdentifierType, .phone)
        XCTAssertEqual(viewModel.credentials.email, "still-invalid")
        XCTAssertEqual(viewModel.credentials.phone, "+1 202 555 1234")
        XCTAssertEqual(viewModel.credentials.password, "Password1")
        XCTAssertEqual(viewModel.credentials.repeatPassword, "Password1")
        XCTAssertTrue(viewModel.credentials.isTermsAccepted)
        XCTAssertNil(viewModel.validationErrors[.email])

        viewModel.credentials.email = "hidden-invalid-email"
        await drainMainQueue()

        XCTAssertNil(viewModel.validationErrors[.email])
    }

    func testRegisterEnablementUsesSelectedIdentifierAndCompletePasswordRules() async {
        let viewModel = RegisterModule.ViewModel()

        await updateCredentials(
            of: viewModel,
            to: .init(
                email: "participant@example.com",
                phone: "invalid-hidden-phone",
                password: "Password1",
                repeatPassword: "Password1",
                isTermsAccepted: true
            ),
            expectingRegisterEnabled: true
        )
        await updatePassword(of: viewModel, to: "password1", expectingRegisterEnabled: false)
        await updatePassword(of: viewModel, to: "Pass1", expectingRegisterEnabled: false)
        await updatePassword(of: viewModel, to: "Password1", expectingRegisterEnabled: true)

        var mismatchingCredentials = viewModel.credentials
        mismatchingCredentials.repeatPassword = "Password2"
        await updateCredentials(
            of: viewModel,
            to: mismatchingCredentials,
            expectingRegisterEnabled: false
        )

        var termsDeclinedCredentials = viewModel.credentials
        termsDeclinedCredentials.repeatPassword = "Password1"
        termsDeclinedCredentials.isTermsAccepted = false
        await updateCredentials(
            of: viewModel,
            to: termsDeclinedCredentials,
            expectingRegisterEnabled: false
        )
    }

    func testEmailRegistrationSubmitsOnlyEmailAndNavigatesDirectlyToOTP() async {
        let viewModel = RegisterModule.ViewModel()
        await updateCredentials(
            of: viewModel,
            to: .init(
                email: "participant@example.com",
                phone: "+1 202 555 1234",
                password: "Password1",
                repeatPassword: "Password1",
                isTermsAccepted: true
            ),
            expectingRegisterEnabled: true
        )

        await viewModel.didTapSignUp()

        XCTAssertEqual(
            authInteractor.submittedContactIdentifier,
            .email("participant@example.com")
        )
        XCTAssertEqual(authInteractor.submittedPassword, "Password1")
        guard case .otp(_, let gadgets)? = appState.navigation.value.path.last?.screen else {
            XCTFail("Successful registration should append OTP directly")
            return
        }
        XCTAssertTrue(gadgets.isSingle)
        XCTAssertEqual(
            gadgets.first,
            .unverified(identifier: "participant@example.com", type: .email)
        )
    }

    func testPhoneRegistrationSubmitsOnlyPhoneAndNavigatesDirectlyToOTP() async {
        let viewModel = RegisterModule.ViewModel()
        viewModel.selectContactIdentifierType(.phone)
        await updateCredentials(
            of: viewModel,
            to: .init(
                email: "invalid-hidden-email",
                phone: "+1 202 555 1234",
                password: "Password1",
                repeatPassword: "Password1",
                isTermsAccepted: true
            ),
            expectingRegisterEnabled: true
        )

        await viewModel.didTapSignUp()

        XCTAssertEqual(
            authInteractor.submittedContactIdentifier,
            .phone("12025551234")
        )
        XCTAssertEqual(authInteractor.submittedPassword, "Password1")
        guard case .otp(_, let gadgets)? = appState.navigation.value.path.last?.screen else {
            XCTFail("Successful registration should append OTP directly")
            return
        }
        XCTAssertTrue(gadgets.isSingle)
        XCTAssertEqual(
            gadgets.first,
            .unverified(identifier: "+1 202 555 1234", type: .phone)
        )
    }

    func testUnsupportedPhoneRegionStaysSelectedAndBlocksRegistration() async {
        let viewModel = RegisterModule.ViewModel()
        viewModel.selectContactIdentifierType(.phone)
        await updateCredentials(
            of: viewModel,
            to: .init(
                email: "participant@example.com",
                phone: "+44 20 7031 3000",
                password: "Password1",
                repeatPassword: "Password1",
                isTermsAccepted: true
            ),
            expectingRegisterEnabled: false
        )

        guard case .registrationUnavailable? = viewModel.phoneVerificationError else {
            XCTFail("Unsupported phone registration should show the existing inline error")
            return
        }

        await viewModel.didTapSignUp()

        XCTAssertEqual(viewModel.selectedContactIdentifierType, .phone)
        XCTAssertFalse(viewModel.enableRegisterButton)
        XCTAssertNil(authInteractor.submittedContactIdentifier)
        XCTAssertTrue(appState.navigation.value.path.isEmpty)
    }

    func testRegistrationDoesNotSubmitWhenTermsAreDeclined() async {
        let viewModel = RegisterModule.ViewModel()
        await updateCredentials(
            of: viewModel,
            to: .init(
                email: "participant@example.com",
                phone: "",
                password: "Password1",
                repeatPassword: "Password1",
                isTermsAccepted: false
            ),
            expectingRegisterEnabled: false
        )

        await viewModel.didTapSignUp()

        XCTAssertNil(authInteractor.submittedContactIdentifier)
        XCTAssertTrue(appState.navigation.value.path.isEmpty)
    }
}

private extension RegisterViewModelTests {
    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    func updatePassword(
        of viewModel: RegisterModule.ViewModel,
        to password: String,
        expectingRegisterEnabled expectedValue: Bool
    ) async {
        var credentials = viewModel.credentials
        credentials.password = password
        credentials.repeatPassword = password
        await updateCredentials(
            of: viewModel,
            to: credentials,
            expectingRegisterEnabled: expectedValue
        )
    }

    func updateCredentials(
        of viewModel: RegisterModule.ViewModel,
        to credentials: RegisterModule.Credentials,
        expectingRegisterEnabled expectedValue: Bool
    ) async {
        let expectation = expectation(
            description: "Register enablement becomes \(expectedValue)"
        )
        expectation.assertForOverFulfill = false
        let cancellable = viewModel.$enableRegisterButton
            .dropFirst()
            .filter { $0 == expectedValue }
            .sink { _ in expectation.fulfill() }

        viewModel.credentials = credentials

        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
        XCTAssertEqual(viewModel.enableRegisterButton, expectedValue)
    }
}

private final class RegisterAuthInteractorTestDouble: AuthInteractor {
    private(set) var submittedContactIdentifier: ContactIdentifier?
    private(set) var submittedPassword: String?

    func signUp(contactIdentifier: ContactIdentifier, password: String) async throws {
        submittedContactIdentifier = contactIdentifier
        submittedPassword = password
    }

    func signIn(
        contactIdentifier: ContactIdentifier,
        password: String
    ) async throws -> AuthInteractorImpl.SignInResult {
        .success(user: .empty)
    }

    func signInWithApple() async throws -> UserModel {
        .empty
    }

    func signInWithGoogle() async throws -> UserModel {
        .empty
    }

    func deleteAccount() async throws { }
}

private final class RegisterRemoteConfigServiceTestDouble: RemoteConfigService {
    static let supportingUnitedStates: RegisterRemoteConfigServiceTestDouble = .init(
        registrationPhoneRegionPolicy: .init(
            schemaVersion: RegistrationPhoneRegionPolicy.supportedSchemaVersion,
            enabled: true,
            allowedRegions: [
                .init(
                    regionCode: "US",
                    regionName: "United States",
                    callingCode: 1,
                    e164Prefix: "+1"
                )
            ]
        )
    )

    let registrationPhoneRegionPolicy: RegistrationPhoneRegionPolicy

    init(registrationPhoneRegionPolicy: RegistrationPhoneRegionPolicy) {
        self.registrationPhoneRegionPolicy = registrationPhoneRegionPolicy
    }

    func configure() { }

    func fetchAndActivate() async { }
}

private final class RegisterTokenRegistryServiceTestDouble: TokenRegistryService {
    func registerTokens() { }

    func updateDeviceToken(_ token: String) { }

    func updateFCMToken(_ token: String?) { }
}

private final class RegisterAppStateTestDouble: AppState {
    let system: StateStore<SystemState> = .init(inititalValue: .test)
    let navigation: StateStore<NavigationState> = .init(inititalValue: .test)
    let transactions: StateStore<TransactionsState> = .init(inititalValue: .test)
    let balance: StateStore<BalanceState> = .init(inititalValue: .test)
    let createTransaction: StateStore<CreateTransactionState> = .init(inititalValue: .test)
    let createPassword: StateStore<CreatePasswordState> = .init(inititalValue: .test)
    let notifications: StateStore<NotificationsState> = .init(inititalValue: .test)
    let notificationsSettings: StateStore<NotificationsSettingsState> = .init(inititalValue: .test)
    let profile: StateStore<ProfileState> = .init(inititalValue: .test)

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
    ) async { }
}
