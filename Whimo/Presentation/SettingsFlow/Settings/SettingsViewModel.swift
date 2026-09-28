//
//  SettingsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
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
import Utility
import Combine
import Resources
import CommonUI

private typealias Module = SettingsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var isTestMode = false
        @Published private(set) var isSwitchingMode = false
        @Published private(set) var entryAlert: EntryAlert?
        enum EntryAlert { case explanation, synchronizationRequired }
        private var cancellable = CancelBag()
        private var entryAlertID: UUID?

        var list: IdentifiedArrayOf<Row> { .init(uniqueElements: Row.allCases) }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        // MARK: - Dependencies
        @Inject(\.businessModeInteractor) private var businessModeInteractor
        @Inject(\.alertManager) private var alertManager
        @Inject(\.appState) private var appState
        @Inject(\.emailClientService) private var emailClientService

        // MARK: - Init
        init() {
            isTestMode = businessModeInteractor.mode == .test
            businessModeInteractor.changes
                .receive(on: DispatchQueue.main)
                .sink { [weak self] mode in self?.isTestMode = mode == .test }
                .store(in: cancellable)
        }

        // MARK: - ViewModelProtocol
    }
}

// MARK: - Public Methods
extension ViewModel {
    @MainActor
    func sendFeedbackEmail() async {
        log.debug("Opening feedback email")

        do {
            let feedbackRecipient = EmailClientServiceImpl.DefaultEmailRecipients.feedback
            var clientType: EmailClientType = .gmail
            if !emailClientService.checkClientAvailability(.gmail) {
                clientType = .defaultBySettings
            }

            try await emailClientService.openEmailClient(
                clientType,
                to: feedbackRecipient.recipient,
                subject: feedbackRecipient.subject
            )
        } catch {
            #if targetEnvironment(simulator)
            await appState.showError(message: error.localizedDescription)
            #else
            log.error("Failed to open email: \(error)")
            let errorMessage = AppLocale.General.Services.EmailClient.Errors.genericError
            await appState.showError(message: errorMessage)
            #endif
        }
    }
}

// MARK: - Test Environment
extension SettingsModule.ViewModel {
    func isRowEnabled(_ row: SettingsModule.Row) -> Bool {
        switch row {
            case .accountInfo, .changePassword, .notifications:
                return businessModeInteractor.mode == .ordinary && !isSwitchingMode
            case .language, .feedback:
                return !isSwitchingMode
        }
    }

    @MainActor
    func setTestModeEnabled(_ enabled: Bool) async {
        guard !isSwitchingMode, enabled != (businessModeInteractor.mode == .test) else { return }

        if !enabled {
            await switchMode(to: .ordinary)
            return
        }
        guard entryAlert == nil else { return }

        isSwitchingMode = true
        defer { isSwitchingMode = false }
        do {
            try await businessModeInteractor.checkEntry()
            showEntryAlert(.explanation)
        } catch BusinessModeError.synchronizationRequired {
            showEntryAlert(.synchronizationRequired)
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    @MainActor
    func confirmTestModeEntry() async {
        guard takeEntryConfirmation() else { return }

        await switchMode(to: .test)
    }

    @MainActor
    func cancelTestModeEntry() {
        entryAlert = nil
        entryAlertID = nil
    }

    @MainActor
    private func takeEntryConfirmation() -> Bool {
        guard entryAlert == .explanation, !isSwitchingMode else { return false }

        cancelTestModeEntry()
        isSwitchingMode = true
        return true
    }

    @MainActor
    private func switchMode(to mode: BusinessMode) async {
        isSwitchingMode = true
        defer {
            isSwitchingMode = false
            isTestMode = businessModeInteractor.mode == .test
        }
        do {
            try await businessModeInteractor.switchMode(to: mode)
        } catch BusinessModeError.synchronizationRequired {
            showEntryAlert(.synchronizationRequired)
        } catch is CancellationError {
            return
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    @MainActor
    private func showEntryAlert(_ kind: EntryAlert) {
        entryAlert = kind
        let alertID = UUID()
        entryAlertID = alertID
        alertManager.show(.init(
            title: AppLocale.TestMode.entryTitle,
            contentView: AnyView(SettingsModule.EntryContent(isBlocked: kind == .synchronizationRequired)),
            buttons: [.init(title: AppLocale.TestMode.gotIt, action: { [weak self] in
                guard let self else { return }

                if kind == .explanation {
                    // Claim consent before AlertView closes; task scheduling order is not guaranteed.
                    guard self.takeEntryConfirmation() else { return }

                    Task { await self.switchMode(to: .test) }
                } else {
                    self.cancelTestModeEntry()
                }
            })],
            onDismiss: { [weak self] in
                guard self?.entryAlertID == alertID else { return }

                self?.cancelTestModeEntry()
            }
        ))
    }
}
