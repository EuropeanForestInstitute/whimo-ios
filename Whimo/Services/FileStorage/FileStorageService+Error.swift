//
//  FileStorageService+Error.swift
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

// MARK: - Error
extension FileStorageService {
    enum Error: LocalizedError {
        case fileDoesNotExists(url: URL)
        case cantRemoveObject(url: URL, reason: Swift.Error)
        case cantCreateDirectory(url: URL, reson: Swift.Error)
        case cantMoveFile(from: URL, to: URL, reason: Swift.Error)
        case missingData(error: MissingDataError)
        case some(error: Swift.Error)

        var errorDescription: String? {
            switch self {
                case .fileDoesNotExists(let url):
                    "File does not exists at: \(url.path())"
                case .cantRemoveObject(let url, let reason):
                    "Can't remove object at: \(url). Reason: \(reason.localizedDescription)"
                case .cantCreateDirectory(let url, let reason):
                    "Can't create directory at: \(url). Reason: \(reason.localizedDescription)"
                case .cantMoveFile(let from, let to, let reason):
                    "Can't move file from: \(from) to: \(to). Reason: \(reason.localizedDescription)"
                case .missingData(let error):
                    error.localizedDescription
                case .some(let error):
                    "Some error. Description: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - MissingDataError
extension FileStorageService.Error {
    enum MissingDataError: LocalizedError {
        case fileMissingCreationDate(url: URL)
        case fileMissingFileType(url: URL)
        case fileMissingFileSize(url: URL)

        var errorDescription: String? {
            switch self {
                case .fileMissingCreationDate(let url):
                    return "Missing creation date parameter. File: \(url)"
                case .fileMissingFileType(let url):
                    return "Missing file type parameter. File: \(url)"
                case .fileMissingFileSize(let url):
                    return "Missing file size parameter. File: \(url)"
            }
        }
    }
}
