//
//  GadgetDetailsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.08.2025.
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
import Utility

private typealias Module = GadgetDetailsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var newGadget: UserModel.GadgetModel
        @Published private(set) var isSaveButtonEnabled: Bool = false

        private(set) var validationErrors: [KeyboardField: Error] = [:]

        let screenMode: ScreenMode

        var canEditGadget: Bool {
            // If gadget is the only one - cannot edit
            if gadgets.count == 1 {
                log.debug("Gadget edit validation: cannot edit - only one gadget")
                return false
            }

            // If there is at least one unverified gadget - cannot edit
            let hasUnverifiedGadgets = gadgets.elements.contains { !$0.isVerified }
            if hasUnverifiedGadgets {
                log.debug("Gadget edit validation: cannot edit - has unverified gadgets")
                return false
            }

            log.debug("Gadget edit validation: can edit - count=\(gadgets.count), hasUnverified=\(hasUnverifiedGadgets)")
            return true
        }

        // MARK: - Private Properties
        private let gadgets: NonEmptyArray<UserModel.GadgetModel>
        private let phoneNumberFormatter: PhoneNumberFormatter = .flat
        private let phoneNumberValidator: PhoneNumberValidator = .shared
        private let emailValidator: EmailValidator = .shared

        private var cancellable: CancelBag = .init()
        private var keyboardActiveField: KeyboardField?

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.profileRemoteRepository) private var profileRemoteRepository
        @Inject(\.remoteConfigService) private var remoteConfigService

        // MARK: - Init
        init(gadgets: NonEmptyArray<UserModel.GadgetModel>) {
            self.gadgets = gadgets
            self.newGadget = ViewModel.getPrimaryGadget(gadgets: gadgets)
            self.screenMode = .init(from: gadgets)

            setupBinding()
        }

        // MARK: - ViewModelProtocol
        func setKeyboardActiveField(_ keyboardActiveField: KeyboardField?) {
            self.keyboardActiveField = keyboardActiveField
        }

        func didTapVerifyGadget() async {
            switch screenMode {
                case .addGadget:
                    guard canSaveCurrentGadget() else { return }

                    appState.system[\.isLoading] = true
                    defer { appState.system[\.isLoading] = false }

                    let success = await addGadget(gadget: newGadget)
                    guard success else { return }

                    await verifyGadget(gadget: newGadget)
                case .verifyGadget:
                    guard canSaveCurrentGadget() else { return }

                    let oldGadget = ViewModel.getPrimaryGadget(gadgets: gadgets)
                    guard hasGadgetChanges(newGadget, from: oldGadget) else {
                        await verifyGadget(gadget: newGadget)
                        return
                    }

                    appState.system[\.isLoading] = true
                    defer { appState.system[\.isLoading] = false }

                    let newGadget = newGadget
                    let success = await changeGadget(newGadget: newGadget, oldGadget: oldGadget)
                    guard success else { return }

                    await verifyGadget(gadget: newGadget)
                case .editGadget:
                    guard canSaveCurrentGadget() else { return }

                    appState.system[\.isLoading] = true
                    defer { appState.system[\.isLoading] = false }

                    let oldGadget = ViewModel.getPrimaryGadget(gadgets: gadgets)
                    let newGadget = newGadget
                    let success = await changeGadget(newGadget: newGadget, oldGadget: oldGadget)
                    guard success else { return }

                    await verifyGadget(gadget: newGadget)
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    func canSaveCurrentGadget() -> Bool {
        let error: Error?
        switch newGadget.type {
            case .email:
                error = emailValidator.isValid(newGadget.identifier)
            case .phone:
                error = phoneValidationError(newGadget.identifier)
        }

        validationErrors[.gadgetId] = error
        return error == nil
    }

    func phoneValidationError(_ phone: String) -> Error? {
        if let error = phoneNumberValidator.isValid(phone) {
            return error
        }

        let availability = phoneNumberValidator.verificationAvailability(
            for: phone,
            policy: remoteConfigService.registrationPhoneRegionPolicy
        )
        return availability == .available ? nil : PhoneVerificationError.settingsUnavailable
    }

    func setupBinding() {
        $newGadget
            .sink { [weak self] newGadget in
                guard let self else { return }

                self.updatePhoneVerificationValidation(for: newGadget)
                let success: Bool
                let primaryGadget = ViewModel.getPrimaryGadget(gadgets: gadgets)
                switch newGadget.type {
                    case .email:
                        success = self.emailValidator.isValid(newGadget.identifier) == nil
                    case .phone:
                        success = self.phoneValidationError(newGadget.identifier) == nil
                }
                let hasChanges = self.hasGadgetChanges(newGadget, from: primaryGadget)
                let canSubmit = self.screenMode == .verifyGadget || hasChanges
                Task { @MainActor in
                    self.isSaveButtonEnabled = success && canSubmit
                }
            }
            .store(in: cancellable)
        $newGadget
            .map { (newGadget: $0, keyboardActiveField: self.keyboardActiveField) }
            .dropFirst()
            .sink { [weak self] newGadget, keyboardActiveField in
                guard let self else { return }

                switch keyboardActiveField {
                    case .gadgetId:
                        switch newGadget.type {
                            case .email:
                                self.validationErrors[.gadgetId] = self.emailValidator.isValid(newGadget.identifier)
                            case .phone:
                                self.validationErrors[.gadgetId] = self.phoneValidationError(newGadget.identifier)
                        }
                    default:
                        return
                }
            }
            .store(in: cancellable)
    }

    func updatePhoneVerificationValidation(for gadget: UserModel.GadgetModel) {
        guard gadget.type == .phone else {
            if validationErrors[.gadgetId] is PhoneVerificationError {
                validationErrors[.gadgetId] = nil
            }
            return
        }

        guard let error = phoneValidationError(gadget.identifier) as? PhoneVerificationError else {
            if validationErrors[.gadgetId] is PhoneVerificationError {
                validationErrors[.gadgetId] = nil
            }
            return
        }

        validationErrors[.gadgetId] = error
    }

    func hasGadgetChanges(
        _ newGadget: UserModel.GadgetModel,
        from oldGadget: UserModel.GadgetModel
    ) -> Bool {
        guard newGadget.type == oldGadget.type else { return true }

        switch newGadget.type {
            case .email:
                return newGadget.identifier != oldGadget.identifier
            case .phone:
                let oldFormatted = (try? phoneNumberFormatter.string(from: oldGadget.identifier)) ?? ""
                let newFormatted = (try? phoneNumberFormatter.string(from: newGadget.identifier)) ?? ""
                return oldFormatted != newFormatted
        }
    }

    // MARK: - Common
    func verifyGadget(gadget: UserModel.GadgetModel) async {
        let screen: Screen = .otp(parrentFlow: .manualVerification(removeLastValue: 2), gadgets: NonEmptyArray(gadget))
        appState.navigation[\.path].append(.push(screen))
    }

    func addGadget(gadget: UserModel.GadgetModel) async -> Bool {
        do {
            try await profileRemoteRepository.addGadget(gadget: gadget)
            log.debug("Gadget added successfully: \(gadget.identifier)")
            return true
        } catch {
            log.error("Failed to add gadget: \(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
            return false
        }
    }

    func changeGadget(newGadget: UserModel.GadgetModel, oldGadget: UserModel.GadgetModel) async -> Bool {
        do {
            try await profileRemoteRepository.changeGadget(newGadget: newGadget, oldGadget: oldGadget)
            log.debug("Gadget changed successfully from \(oldGadget.identifier) to \(newGadget.identifier)")
            return true
        } catch {
            log.error("Failed to change gadget: \(error.localizedDescription)")
            await appState.showError(message: error.localizedDescription)
            return false
        }
    }

    // MARK: - Static
    static func getPrimaryGadget(gadgets: NonEmptyArray<UserModel.GadgetModel>) -> UserModel.GadgetModel {
        gadgets.first
    }
}
