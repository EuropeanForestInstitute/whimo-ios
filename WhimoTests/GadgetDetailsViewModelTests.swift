//
//  GadgetDetailsViewModelTests.swift
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

import Combine
import XCTest
import FactoryKit
import Utility
@testable import Whimo

@MainActor
final class GadgetDetailsViewModelTests: XCTestCase {
    private var remoteConfigService: RemoteConfigServiceMock!
    private var profileRemoteRepository: ProfileRemoteRepositoryMock!

    override func setUp() {
        super.setUp()

        AppContainer.shared.manager.push()
        remoteConfigService = .init(
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
        profileRemoteRepository = .init()
        guard let remoteConfigService, let profileRemoteRepository else {
            XCTFail("Test dependencies should be initialized")
            return
        }
        AppContainer.shared.remoteConfigService
            .register { remoteConfigService }
            .scope(.unique)
        AppContainer.shared.profileRemoteRepository
            .register { profileRemoteRepository }
            .scope(.unique)
    }

    override func tearDown() {
        AppContainer.shared.manager.pop()
        profileRemoteRepository = nil
        remoteConfigService = nil

        super.tearDown()
    }

    func testPhoneTextFieldValueAddsOnlyAMissingInternationalPrefix() {
        XCTAssertEqual(
            GadgetDetailsModule.phoneTextFieldValue(for: "442070313000"),
            "+442070313000"
        )
        XCTAssertEqual(
            GadgetDetailsModule.phoneTextFieldValue(for: "+442070313000"),
            "+442070313000"
        )
    }

    func testVerifyGadgetReplacesUnsupportedPhoneBeforeStartingVerification() async {
        let oldGadget = UserModel.GadgetModel.unverified(
            identifier: "+44 20 7031 3000",
            type: .phone
        )
        let newGadget = UserModel.GadgetModel.unverified(
            identifier: "+1 202 555 1234",
            type: .phone
        )
        let viewModel = GadgetDetailsModule.ViewModel(gadgets: .init(oldGadget))

        XCTAssertFalse(viewModel.isSaveButtonEnabled)
        guard case .settingsUnavailable? = viewModel.validationErrors[.gadgetId] as? PhoneVerificationError else {
            XCTFail("The unsupported phone should be blocked from verification")
            return
        }

        let enabledExpectation = expectation(description: "Verification becomes available for the replacement phone")
        let cancellable = viewModel.$isSaveButtonEnabled
            .dropFirst()
            .filter { $0 }
            .sink { _ in
                enabledExpectation.fulfill()
            }
        viewModel.newGadget = newGadget

        XCTAssertNil(
            viewModel.validationErrors[.gadgetId],
            "The replacement phone should be allowed by the test policy"
        )

        await fulfillment(of: [enabledExpectation], timeout: 1)
        cancellable.cancel()
        XCTAssertTrue(viewModel.isSaveButtonEnabled)

        await viewModel.didTapVerifyGadget()

        XCTAssertEqual(profileRemoteRepository.changedOldGadget, oldGadget)
        XCTAssertEqual(profileRemoteRepository.changedNewGadget, newGadget)
    }

    func testVerifyGadgetEnablesExistingSupportedPhoneWithoutReplacingIt() async {
        let gadget = UserModel.GadgetModel.unverified(
            identifier: "+1 202 555 1234",
            type: .phone
        )
        let viewModel = GadgetDetailsModule.ViewModel(gadgets: .init(gadget))

        let enabledExpectation = expectation(description: "Verification remains available for a supported existing phone")
        let cancellable = viewModel.$isSaveButtonEnabled
            .filter { $0 }
            .sink { _ in
                enabledExpectation.fulfill()
            }

        await fulfillment(of: [enabledExpectation], timeout: 1)
        cancellable.cancel()

        await viewModel.didTapVerifyGadget()

        XCTAssertNil(profileRemoteRepository.changedOldGadget)
        XCTAssertNil(profileRemoteRepository.changedNewGadget)
    }
}

private final class RemoteConfigServiceMock: RemoteConfigService, @unchecked Sendable {
    let registrationPhoneRegionPolicy: RegistrationPhoneRegionPolicy

    init(registrationPhoneRegionPolicy: RegistrationPhoneRegionPolicy) {
        self.registrationPhoneRegionPolicy = registrationPhoneRegionPolicy
    }

    func configure() { }

    func fetchAndActivate() async { }
}

private final class ProfileRemoteRepositoryMock: ProfileRemoteRepository, @unchecked Sendable {
    private(set) var changedOldGadget: UserModel.GadgetModel?
    private(set) var changedNewGadget: UserModel.GadgetModel?

    func fetchProfile() async throws -> UserModel {
        .empty
    }

    func checkGadgetExists(_ identifier: String) async throws -> Bool {
        false
    }

    func changePassword(currentPassword: String, newPassword: String) async throws { }

    func deleteProfile() async throws { }

    func addGadget(gadget: UserModel.GadgetModel) async throws { }

    func changeGadget(
        newGadget: UserModel.GadgetModel,
        oldGadget: UserModel.GadgetModel
    ) async throws {
        changedOldGadget = oldGadget
        changedNewGadget = newGadget
    }
}
