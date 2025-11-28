//
//  UploadFile+FilePickerInteractor.swift
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
import Utility

private typealias Module = UploadFileModule
private typealias InteractorProtocol = Module.InteractorProtocol
private typealias Interactor = Module.FilePickerInteractor

// MARK: - FilePickerInteractor
extension Module {
    final class FilePickerInteractor: InteractorProtocol {
        // MARK: - Error
        enum Error: LocalizedError {
            case emptyFile
            case cannotFindFarmCoordinates
            case accessDenied

            var errorDescription: String? {
                switch self {
                    case .emptyFile:
                        "Selected file empty."
                    case .cannotFindFarmCoordinates:
                        "Cannot find farm coordinates in provided file."
                    case .accessDenied:
                        "Cannot read file. Access denied."
                }
            }
        }

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.fileStorage) private var fileStorage
        private let parser: FileCoordinatesParser = .init()

        // MARK: - InteractorProtocol
        func processFile(selectedFile: FileObject) {
            let fileURL = selectedFile.url

            do {
                guard
                    fileURL.startAccessingSecurityScopedResource()
                else { throw Error.accessDenied }

                let fileData: Data? = fileStorage.contents(of: fileURL)

                fileURL.stopAccessingSecurityScopedResource()

                guard
                    let fileData,
                    let stringData: String = .init(data: fileData, encoding: .utf8)
                else { throw Error.emptyFile }

                let coordinatesArray = (try? parser.parse(stringData)) ?? []
                guard
                    let coordinates = coordinatesArray.first
                else { throw Error.cannotFindFarmCoordinates }

                let formatedCoordinates: CLLocationCoordinate2D = .init(latitude: coordinates.longitude, longitude: coordinates.latitude)
                selectFarmLocation(file: selectedFile, coordinates: formatedCoordinates)
                goBack()
            } catch {
                appState.showError(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Private Methods
private extension Interactor {
    func selectFarmLocation(file: FileObject, coordinates: CLLocationCoordinate2D) {
        appState.createTransaction[\.farmLocation] = .fileManager(file: file, coordinates: coordinates)
    }

    func goBack() {
        let navigationStack = appState.navigation.value.path
        let prevScreen = Array(navigationStack.suffix(2))
        switch prevScreen.first?.screen {
            case .chooseFarmGeodata:
                appState.navigation[\.path].removeLast(2)
                return
            default:
                appState.navigation[\.path].removeLast()
                return
        }
    }
}
