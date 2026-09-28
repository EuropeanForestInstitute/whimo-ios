//
//  URLDocument.swift
//  Utility
//
//  Created by Vyacheslav Razumeenko on 04.09.2025.
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

/// A FileDocument that handles URL-based file operations for CSV, GeoJSON, and ZIP files.
/// Provides a unified interface for reading and writing files from local file system URLs.
///
/// ## Extending URLDocument
/// To add support for new file types:
/// 1. Create a new FileDocument struct (e.g., `PDFDocument`)
/// 2. Add its `readableContentTypes` to the `readableContentTypes` array:
///    ```swift
///    public static var readableContentTypes: [UTType] {
///        CSVDocument.readableContentTypes
///        + GeoJSONDocument.readableContentTypes
///        + ZipDocument.readableContentTypes
///        + PDFDocument.readableContentTypes  // Add new type here
///    }
///    ```
/// 3. The `fileWrapper` method will automatically handle the new file type through the URL path.
public struct URLDocument: FileDocument {
    public var url: String = ""

    public static var readableContentTypes: [UTType] {
        CSVDocument.readableContentTypes
        + GeoJSONDocument.readableContentTypes
        + ZipDocument.readableContentTypes
    }

    public init(_ url: String) {
        self.url = url
    }

    public init(configuration: ReadConfiguration) throws {
        self.url = ""
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let url: URL = .init(filePath: self.url)
        return try FileWrapper(url: url, options: .immediate)
    }
}
