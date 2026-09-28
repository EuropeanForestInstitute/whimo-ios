//
//  DocumentPicker+Coordinator.swift
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

import SwiftUI
import Utility

// MARK: - Coordinator
public extension DocumentPicker {
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        // MARK: - Private Properties
        private var parent: DocumentPicker

        // MARK: - Init
        public init(parent: DocumentPicker) {
            self.parent = parent
        }

        // MARK: - UIDocumentPickerDelegate
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            // Start accessing a security-scoped resource.
            guard url.startAccessingSecurityScopedResource() else {
                log.error("Cannot get permission read file")
                return
            }

            parent.didPickData(url)

            // Release the security-scoped resource when you are done.
            url.stopAccessingSecurityScopedResource()
        }
    }
}
