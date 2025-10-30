//
//  ScanQRViewModel.swift
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
import Combine
import AudioToolbox
import struct CoreLocation.CLLocationCoordinate2D
import Utility

private typealias Module = ScanQRModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var payload: String = ""

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()
        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.qrCodeDataService) private var qrCodeDataService

        // MARK: - Init
        init() {
            setupBinding()
        }

        // MARK: - ViewModelProtocol
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        $payload
            .dropFirst()
            .handleEvents(receiveOutput: { code in log.debug("\n\(code)") })
            .sink { [weak self] code in
                guard let self else { return }

                do {
                    let farmInfo = try self.qrCodeDataService.getFarmInfo(from: code)
                    let file = self.qrCodeDataService.createFile(geojson: farmInfo.geojson)
                    self.saveData(farmInfo.locationPoint, selectedFile: file)
                } catch {
                    appState.showError(message: error.localizedDescription)
                }
            }
            .store(in: cancellable)
    }

    // MARK: - Common
    func saveData(_ coordinates: CLLocationCoordinate2D, selectedFile: FileObject?) {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        guard let selectedFile else { return }

        appState.createTransaction[\.farmLocation] = .qrCode(file: selectedFile, coordinates: coordinates)
        appState.navigation[\.path].removeLast(2)
    }
}
