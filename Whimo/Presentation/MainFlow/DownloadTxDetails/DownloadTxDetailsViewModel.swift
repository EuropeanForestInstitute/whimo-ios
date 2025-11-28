//
//  DownloadTxDetailsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.09.2025.
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
import class CommonUI.AlertManager
import Resources

private typealias Module = DownloadTxDetailsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        let options: [DownloadOption] = DownloadOption.allCases
        @Published var showExporter: ExporterPresentation?

        // MARK: - Private Properties
        private let transactionId: String
        private let tradersCount: Int
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.alertManager) private var alertManager
        @Inject(\.transactionDocumentsService) private var transactionDocumentsService

        // MARK: - Init
        init(transactionId: String, tradersCount: Int) {
            self.transactionId = transactionId
            self.tradersCount = tradersCount
        }

        // MARK: - ViewModelProtocol
        func showDownloadTxDetailsAlert() {
            typealias Localization = AppLocale.General.Alert.DownloadTxDetails
            typealias AlertFeature = AlertManager.AlertModel.Features.DownloadTxDetails

            var alert = AlertFeature.alert
            alert.subtitle = Localization.subtitle("\(tradersCount)")
            let buttons: [AlertManager.AlertModel.Button] = AlertFeature.ActionKeys.allCases.map { key in
                var button = key.button
                switch key {
                    case .download:
                        button.action = didTapDownloadDetails
                        return button
                    case .cancel:
                        return button
                }
            }
            alert.buttons = buttons
            alertManager.show(alert)
        }

        func showDownloadZipAlert() {
            typealias AlertType = AlertManager.AlertModel.Features.DownloadFarmLocations
            var alert = AlertType.alert
            alert.contentView = .init(Module.FarmLocationsPopup())

            let buttons: [AlertManager.AlertModel.Button] = AlertType.ActionKeys.allCases.map { key in
                var button = key.button
                switch key {
                    case .cancel:
                        return button
                    case .download:
                        button.action = didTapDownloadZip
                        return button
                }
            }
            alert.buttons = buttons

            alertManager.show(alert)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    func downloadZip(transactionId: String) async {
        do {
            let zipFile = try await transactionDocumentsService.downloadDocumentsBundle(transactionId: transactionId)
            await MainActor.run { [weak self] in
                self?.showExporter = .showZipExporter(file: zipFile)
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func downloadDetails(transactionId: String) async {
        do {
            let csvDocument = try await transactionDocumentsService.downloadCSV(transactionId: transactionId)
            await MainActor.run { [weak self] in
                self?.showExporter = .showCsvExporter(file: csvDocument)
            }
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func didTapDownloadZip() {
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            await self.downloadZip(transactionId: self.transactionId)
        }
    }

    func didTapDownloadDetails() {
        Task { [weak self] in
            guard let self else { return }

            self.appState.system[\.isLoading] = true
            defer { self.appState.system[\.isLoading] = false }

            await self.downloadDetails(transactionId: self.transactionId)
        }
    }
}
