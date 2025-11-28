//
//  DocumentPickerView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 20.05.2025.
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
import SwiftUI
import UniformTypeIdentifiers
import Extensions

/// File selector control
public struct DocumentPicker: UIViewControllerRepresentable {
    public typealias Controller = UIDocumentPickerViewController

    public let didPickData: (_ url: URL) -> Void

    public init(didPickData: @escaping (_: URL) -> Void) {
        self.didPickData = didPickData
    }

    public func makeUIViewController(context: Context) -> Controller {
        let supportedTypes = buildSupportedTypes()
        let controller: Controller = .init(forOpeningContentTypes: supportedTypes, asCopy: false)

        controller.allowsMultipleSelection = false
        controller.delegate = context.coordinator

        return controller
    }

    public func updateUIViewController(_ uiViewController: Controller, context: Context) { }

    public func makeCoordinator() -> Coordinator { .init(parent: self) }
}

// MARK: - Private Methods {
private extension DocumentPicker {
    func buildSupportedTypes() -> [UTType] {
        let supportedTypes: [UTType] = [
            .geoJSONUniversal, // .geojson
            .commaSeparatedText // .csv
        ].compactMap { $0 }

        return supportedTypes
    }
}
