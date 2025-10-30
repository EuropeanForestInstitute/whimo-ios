//
//  UploadFileViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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
import struct CoreLocation.CLLocationCoordinate2D

private typealias Module = UploadFileModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var selectedFile: FileObject?

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.fileStorage) private var fileStorage

        private let interactor: any InteractorProtocol

        // MARK: - Init
        init(mode: Mode) {
            @Inject(\.appState) var appState
            if case .fileManager(let file, _) = appState.createTransaction.value.farmLocation {
                self.selectedFile = file
            }
            switch mode {
                case .filePicker:
                    self.interactor = FilePickerInteractor()
                case .fileUploader(transactionId: let transactionId):
                    self.interactor = FileUploaderInteractor(transactionId: transactionId)
            }
        }

        // MARK: - ViewModelProtocol
        func didTapUploadFile() {
            openDocumentPicker()
        }

        func didTapUploadAnotherFile() {
            openDocumentPicker()
        }

        func didTapRemoveSelectedFile() {
            selectedFile = nil
        }

        func didTapConfirm() {
            guard let selectedFile else { return }

            interactor.processFile(selectedFile: selectedFile)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Navigation
    func openDocumentPicker() {
        let screen: Screen = .documentPicker(documentPickerDidPick(url:))
        appState.navigation[\.path].append(.sheet(screen))
    }

    // MARK: - DocumentPickerOutput
    func documentPickerDidPick(url: URL) {
        log.debug("url: \(url)")

        #if DEBUG
        let resultData: Data? = fileStorage.contents(of: url)
        if let resultData, let string: String = .init(data: resultData, encoding: .utf8) {
            log.debug("stringData: \(string)")
        }
        #endif

        let result: Result = fileStorage.contents(of: url)
        switch result {
            case .success(let files):
                log.debug("files: \(files)")
                log.debug("mimeTypes: \(files.map({ $0.mimeType }))")

                self.selectedFile = files.first
            case .failure(let error):
                log.debug("error: \(error)")
        }
    }
}
