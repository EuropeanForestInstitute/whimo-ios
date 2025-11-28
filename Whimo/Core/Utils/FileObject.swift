//
//  FileObject.swift
//  Whimo
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
import UniformTypeIdentifiers
import protocol Utility.AutoStringConvertible

struct FileObject: Equatable, AutoStringConvertible {
    // MARK: - Private Helpers
    private static let byteFormatter: ByteCountFormatter = .defaultFormatter
    private static let dateFormatter: DateTimeFormatter = .fileObject

    // MARK: - Properties
    let id: String
    let url: URL
    let creationDate: Date
    let fileType: FileAttributeType
    let size: NSNumber
    let childs: [FileObject]

    var totalSize: Int64 {
        guard isDirectory else { return Int64(truncating: size) }
        return childs.map(\.totalSize).reduce(0, +)
    }

    var fileExtension: UTType? {
        .init(filenameExtension: url.pathExtension.lowercased())
    }

    var mimeType: String {
        if let mimeType = fileExtension?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }

    var isDirectory: Bool {
        fileType == .typeDirectory
    }

    // MARK: - Methods
    func formattedSize() -> String {
        FileObject.byteFormatter.string(fromByteCount: totalSize)
    }

    func formattedDate() -> String {
        FileObject.dateFormatter.string(from: creationDate)
    }
}
