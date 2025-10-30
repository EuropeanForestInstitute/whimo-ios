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
import enum Resources.LocalizeKeys
import class CommonUI.AlertManager

private typealias Module = OTPModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var gadgets: NonEmptyArray<UserModel.GadgetModel>
        @Published var otp: String = ""

        var selectedGadget: UserModel.GadgetModel { gadgets.first }
        var showChangeVerifyMethodButton: Bool { !gadgets.isSingle }
        var enableConfirmButton: Bool { otp.count == 6 }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        private let parrentFlow: ParrentFlow

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.authService) private var authService
        @Inject(\.profileService) private var profileService
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

                    try? await profileService.fetchProfile()
                    appState.navigation.dispatch { state in
                        state.path.removeLast(removeLastValue)
                    }
                    return
            }
        }

        func didTapResendCode() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }
            let selectedGadget = self.selectedGadget

            await interactor.sendOTP(gadget: selectedGadget)
        }

        func didTapSwitchGadget() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }
            let selectedGadget = self.selectedGadget

            let success = await interactor.sendOTP(gadget: selectedGadget)
            guard success else { return }

            await MainActor.run {
                withAnimation(.snappy) {
                    gadgets = NonEmptyArray(gadgets.elements.reversed()) ?? gadgets
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func startup() {
        Task { [weak self] in
            guard let self else { return }

            let selectedGadget = self.selectedGadget

            await self.interactor.sendOTP(gadget: selectedGadget)
        }
    }

    // MARK: - Common
    func signInRequest(gadget: UserModel.GadgetModel, password: String) async -> Bool {
        do {
            let authMethod: AuthRepositoryImpl.AuthMethod
            switch gadget.type {
                case .email:
                    authMethod = .email(gadget.identifier)
                case .phone:
                    authMethod = .phone(gadget.identifier)
            }

            _ = try await authService.signIn(authMethod: authMethod, password: password)

            return true
        } catch {
            log.debug("error: \(error). \nlocalizedDescription:\(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
        }

        return false
    }
}
