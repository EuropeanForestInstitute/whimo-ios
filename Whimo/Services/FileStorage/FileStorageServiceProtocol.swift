//
//  FileStorageServiceProtocol.swift
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

import Combine
import Foundation

// MARK: - FileStorageServiceProtocol
protocol FileStorageServiceProtocol: AnyObject {
    var files: AnyPublisher<[FileObject], Never> { get }

    func fetchFiles()
    func isFileExists(at url: URL) -> Bool
    func isFileExists(at url: URL) -> (isExists: Bool, isDirectory: Bool)
    @discardableResult
    func createDirectoryIfNotExist(at url: URL) -> FileStorageService.Error?
    @discardableResult
    func createFileIfNotExist(
        at url: URL,
        content: Data?
    ) -> Bool
    @discardableResult
    func createFile(
        at url: URL,
        content: Data?,
        overwrite: Bool
    ) -> Bool
    func move(from: URL, to: URL) throws -> FileStorageService.Error?
    func contents(of url: URL) -> Result<[FileObject], FileStorageService.Error>
    func contents(of file: URL, securityScoped: Bool) -> Data?
    func deleteObject(at url: URL) -> FileStorageService.Error?
    func deleteObject(_ object: FileObject) -> FileStorageService.Error?
}

extension FileStorageServiceProtocol {
    @discardableResult
    func createFile(
        at url: URL,
        content: Data?,
        overwrite: Bool = true
    ) -> Bool {
        createFile(at: url, content: content, overwrite: overwrite)
    }

    func contents(of file: URL, securityScoped: Bool = false) -> Data? {
        contents(of: file, securityScoped: securityScoped)
    }
}
