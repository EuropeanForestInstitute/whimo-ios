//
//  NotificationsSettingsInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.07.2025.
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
import RestClient
import Utility

final class NotificationsSettingsInteractorImpl: NotificationsSettingsInteractor {
    // MARK: - Dependencies
    private let appState: AppState
    private let notificationsSettingsRepository: NotificationsSettingsCachingRepository

    // MARK: - Init
    init(
        appState: AppState,
        notificationsSettingsRepository: NotificationsSettingsCachingRepository
    ) {
        self.appState = appState
        self.notificationsSettingsRepository = notificationsSettingsRepository
    }

    // MARK: - NotificationsSettingsInteractor
    func fetchSettings() async throws {
        let settingsList = try await notificationsSettingsRepository.fetchSettingsList()
        appState.notificationsSettings.dispatch { state in
            state.settingsList = settingsList
        }
    }

    func updateSettings(_ settingsList: IdentifiedArrayOf<NotificationsSettingsModel>) async throws {
        let requestSettings: [RequestModels.NotificationsSettings] = settingsList.map {
            let settingsType: RequestModels.NotificationsSettings.SettingsType
            switch $0.type {
                case .geodataMissing:
                    settingsType = .geodataMissing
                case .geodataUpdated:
                    settingsType = .geodataUpdated
                case .transactionAccepted:
                    settingsType = .transactionAccepted
                case .transactionExpired:
                    settingsType = .transactionExpired
                case .transactionPending:
                    settingsType = .transactionPending
                case .transactionRejected:
                    settingsType = .transactionRejected
            }

            return .init(type: settingsType, isEnabled: $0.isEnabled)
        }

        try await notificationsSettingsRepository.updateSettings(requestSettings)
        appState.notificationsSettings.dispatch { state in
            state.settingsList = settingsList
        }
    }
}
