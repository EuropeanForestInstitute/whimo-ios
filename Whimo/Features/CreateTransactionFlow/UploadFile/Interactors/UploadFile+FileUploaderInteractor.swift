//
//  UploadFile+FileUploaderInteractor.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 14.06.2025.
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
import struct CoreLocation.CLLocationCoordinate2D

private typealias Module = UploadFileModule
private typealias InteractorProtocol = Module.InteractorProtocol
private typealias Interactor = Module.FileUploaderInteractor

extension Module {
    final class FileUploaderInteractor: InteractorProtocol {
        // MARK: - Private Properties
        let transactionId: String

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.transactionService) private var transactionService

        // MARK: - Init
        init(transactionId: String) {
            self.transactionId = transactionId
        }

        // MARK: - InteractorProtocol
        func processFile(selectedFile: FileObject) {
            Task { [weak self] in
                guard let self else { return }

                await self.processFile(transactionId: self.transactionId, selectedFile: selectedFile)
            }
        }
    }
}

// MARK: - Private Methods
private extension Interactor {
    func processFile(transactionId: String, selectedFile: FileObject) async {
        appState.system[\.isLoading] = true
        defer { appState.system[\.isLoading] = false }

        do {
            try await transactionService.updateTransactionGeodata(transactionId: transactionId, file: selectedFile)
            try await transactionService.fetchTransaction(by: transactionId)
            goBack()
        } catch {
            await appState.showError(message: error.localizedDescription)
        }
    }

    func goBack() {
        appState.navigation[\.path].removeLast()
    }
}
