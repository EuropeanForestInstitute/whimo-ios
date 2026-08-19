//
//  OTPViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 01.05.2025.
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

import SwiftUI
import StorageKit
import Utility
import enum Resources.AppLocale
import enum Resources.LocalizeKeys
import class CommonUI.AlertManager

private typealias Module = OTPModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    @MainActor
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var gadgets: NonEmptyArray<UserModel.GadgetModel>
        @Published var otp: String = ""
        @Published var isCaptchaPresented: Bool = false

        var selectedGadget: UserModel.GadgetModel { gadgets.first }
        var showChangeVerifyMethodButton: Bool { !gadgets.isSingle }
        var enableConfirmButton: Bool { otp.count == 6 }
        var navigationTitle: String {
            switch selectedGadget.type {
                case .email:
                    AppLocale.Otp.title
                case .phone:
                    AppLocale.Otp.smsTitle
            }
        }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()
        private var pendingSendOperation: SendOperation?
        private var approvedSendAttempt: ApprovedSendAttempt?
        private var isProtectedRequestInFlight = false

        private let parrentFlow: ParrentFlow

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.authInteractor) private var authInteractor
        @Inject(\.profileInteractor) private var profileInteractor
        @Inject(\.tokenRegistryService) private var tokenRegistryService

        private let interactor: InteractorProtocol

        // MARK: - Init
        init(parrentFlow: ParrentFlow, gadgets: NonEmptyArray<UserModel.GadgetModel>) {
            self.parrentFlow = parrentFlow
            self.gadgets = gadgets

            switch parrentFlow {
                case .singUp:
                    self.interactor = DefaultInteractor()
                case .restorePassword:
                    self.interactor = ForgotPasswordInteractor()
                case .manualVerification:
                    self.interactor = DefaultInteractor()
            }

            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirm() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }
            let selectedGadget = self.selectedGadget

            let success = await interactor.verifyOTP(gadget: selectedGadget, otp: otp)
            guard success else { return }

            switch parrentFlow {
                case .singUp(let credentials):
                    let success = await signInRequest(gadget: selectedGadget, password: credentials.password)
                    guard success else { return }

                    tokenRegistryService.registerTokens()
                    appState.navigation.send(.authorized)
                    appState.navigation.dispatch { state in
                        state.path = [.root(.tabBar, embedInNavigationView: true)]
                    }
                    return
                case .restorePassword:
                    appState.createPassword[\.gadgetId] = selectedGadget.identifier
                    appState.createPassword[\.otpCode] = otp

                    appState.navigation.dispatch { state in
                        state.path.append(.push(.createPassword))
                    }
                    return
                case .manualVerification(let removeLastValue):
                    var alert: AlertManager.AlertModel
                    switch selectedGadget.type {
                        case .email:
                            alert = AlertManager.AlertModel.Features.EmailAdded.alert
                            alert.contentView = .init(Module.GadgedAddedPopup(gadget: .email(identifier: selectedGadget.identifier)))
                        case .phone:
                            alert = AlertManager.AlertModel.Features.PhoneAdded.alert
                            alert.contentView = .init(Module.GadgedAddedPopup(gadget: .phone(identifier: selectedGadget.identifier)))
                    }

                    alertManager.show(alert)

                    try? await profileInteractor.fetchProfile()
                    appState.navigation.dispatch { state in
                        state.path.removeLast(removeLastValue)
                    }
                    return
            }
        }

        func didTapResendCode() {
            beginCaptchaChallenge(for: .resend(gadget: selectedGadget))
        }

        func didTapSwitchGadget() {
            beginCaptchaChallenge(for: .switchGadget(gadget: selectedGadget))
        }

        func didCompleteCaptchaChallenge(_ outcome: CaptchaChallengeModule.Outcome) {
            guard let pendingSendOperation else { return }

            self.pendingSendOperation = nil
            isCaptchaPresented = false

            switch outcome {
                case .token(let token):
                    approvedSendAttempt = .init(
                        operation: pendingSendOperation,
                        captchaToken: token
                    )
                case .cancelled:
                    approvedSendAttempt = nil
                    if pendingSendOperation.isInitial {
                        appState.navigation.dispatch { state in
                            guard !state.path.isEmpty else { return }

                            state.path.removeLast()
                        }
                    }
                case .failure:
                    approvedSendAttempt = nil
            }
        }

        @discardableResult
        func didDismissCaptchaChallenge() async -> Bool {
            guard let approvedSendAttempt else { return false }

            self.approvedSendAttempt = nil
            isProtectedRequestInFlight = true
            defer { isProtectedRequestInFlight = false }

            let success = await sendProtectedOTP(for: approvedSendAttempt)
            guard success else { return false }

            guard approvedSendAttempt.operation.switchesGadget else { return true }

            await MainActor.run {
                withAnimation(.snappy) {
                    gadgets = NonEmptyArray(gadgets.elements.reversed()) ?? gadgets
                }
            }

            return true
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func startup() {
        beginCaptchaChallenge(for: .initial(gadget: selectedGadget))
    }

    // MARK: - Captcha
    func beginCaptchaChallenge(for operation: SendOperation) {
        guard
            pendingSendOperation == nil,
            approvedSendAttempt == nil,
            !isProtectedRequestInFlight
        else { return }

        pendingSendOperation = operation
        isCaptchaPresented = true
    }

    func sendProtectedOTP(for attempt: ApprovedSendAttempt) async -> Bool {
        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        return await interactor.sendOTP(
            gadget: attempt.operation.gadget,
            captchaToken: attempt.captchaToken
        )
    }

    // MARK: - Common
    func signInRequest(gadget: UserModel.GadgetModel, password: String) async -> Bool {
        do {
            let contactIdentifier: ContactIdentifier
            switch gadget.type {
                case .email:
                    contactIdentifier = .email(gadget.identifier)
                case .phone:
                    contactIdentifier = .phone(gadget.identifier)
            }

            _ = try await authInteractor.signIn(contactIdentifier: contactIdentifier, password: password)

            return true
        } catch {
            log.debug("error: \(error). \nlocalizedDescription:\(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }
}

// MARK: - Captcha Send State
private extension ViewModel {
    enum SendOperation {
        case initial(gadget: UserModel.GadgetModel)
        case resend(gadget: UserModel.GadgetModel)
        case switchGadget(gadget: UserModel.GadgetModel)

        var gadget: UserModel.GadgetModel {
            switch self {
                case .initial(let gadget), .resend(let gadget), .switchGadget(let gadget):
                    gadget
            }
        }

        var switchesGadget: Bool {
            if case .switchGadget = self {
                return true
            }
            return false
        }

        var isInitial: Bool {
            if case .initial = self {
                return true
            }
            return false
        }
    }

    struct ApprovedSendAttempt {
        let operation: SendOperation
        let captchaToken: String
    }
}
