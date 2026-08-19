//
//  NotificationsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import enum Resources.LocalizeKeys

private typealias Module = NotificationsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var optionsList: IdentifiedArrayOf<RowData> = []
        @Published var defaultOption: RowData = .defaultOption(isEnabled: true)
        @Published var connectionReachable: Bool = true

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.notificationsSettingsInteractor) private var notificationsSettingsInteractor
        @Inject(\.connectivity) private var connectivity
        @Inject(\.permissionsService) private var permissionsService

        // MARK: - Init
        init() {
            @Inject(\.appState) var appState
            let state = appState.notificationsSettings.value
            self.optionsList = Module.RowData.toArray(state.settingsList)

            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapToggle(item: RowData) {
            if item.rowType == .allowNotifications {
                defaultOption = .defaultOption(isEnabled: item.isEnabled)
                appState.navigation.value.openSystemSettings()
                return
            }

            optionsList[id: item.id]?.isEnabled = item.isEnabled
        }

        func didTapSave() async {
            appState.system[\.isLoading] = true
            defer { appState.system[\.isLoading] = false }

            let settings = Module.RowData.toDomain(optionsList)
            do {
                try await notificationsSettingsInteractor.updateSettings(settings)
            } catch {
                await appState.showError(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        connectivity.isReachable
            .receive(on: DispatchQueue.main)
            .map { status in
                switch status {
                    case .notReachable:
                        return false
                    case .reachable:
                        return true
                    case .unknown:
                        return true
                }
            }
            .weakAssign(on: self, to: \.connectionReachable)
            .store(in: cancellable)
        permissionsService.notificationsPermissonsStatus
            .receive(on: DispatchQueue.main)
            .map {
                switch $0 {
                    case .notDetermined, .denied:
                        .defaultOption(isEnabled: false)
                    case .authorized, .provisional, .ephemeral:
                        .defaultOption(isEnabled: true)
                    @unknown default:
                        .defaultOption(isEnabled: false)
                }
            }
            .weakAssign(on: self, to: \.defaultOption)
            .store(in: cancellable)
        appState.notificationsSettings.state
            .map(\.settingsList)
            .map { Module.RowData.toArray($0) }
            .weakAssign(on: self, to: \.optionsList)
            .store(in: cancellable)
    }

    func startup() {
        Task { [weak self] in
            guard let self else { return }

            try? await self.notificationsSettingsInteractor.fetchSettings()
        }
    }
}
