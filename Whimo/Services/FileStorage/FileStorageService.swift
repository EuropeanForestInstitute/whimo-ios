//
//  FileStorageService.swift
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
import Combine
import Utility

// MARK: - FileStorageService
class FileStorageService: FileStorageServiceProtocol {
    // MARK: - Properties
    var files: AnyPublisher<[FileObject], Never> { _files.eraseToAnyPublisher() }

    // MARK: - Private Properties
    // swiftlint:disable:next identifier_name
    private var _files: CurrentValueSubject<[FileObject], Never> = .init(.init())

    // MARK: - Private Dependencies
    private let fileManager: FileManager

    // MARK: - Init
    init() {
        self.fileManager = .default
    }

    // MARK: - FileStorageServiceProtocol
    func fetchFiles() {
        let result: Result<[FileObject], FileStorageService.Error> = contents(of: FileUtils.directoryURL)
        if case let .success(objects) = result {
            _files.send(objects)
        }
    }

    func isFileExists(at url: URL) -> Bool {
        isFileExists(at: url).isExists
    }

    func isFileExists(at url: URL) -> (isExists: Bool, isDirectory: Bool) {
        var isDirectory: ObjCBool = false
        let isExists: Bool = fileManager.fileExists(
            atPath: url.path(percentEncoded: false),
            isDirectory: &isDirectory
        )
        return (isExists, isDirectory.boolValue)
    }

    func createDirectoryIfNotExist(at url: URL) -> FileStorageService.Error? {
        if !isFileExists(at: url) {
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true
                )
                return nil
            } catch {
                return .cantCreateDirectory(url: url, reson: error)
            }
        }
        return nil
    }

    @discardableResult
    func createFileIfNotExist(
        at url: URL,
        content: Data?
    ) -> Bool {
        if !isFileExists(at: url) {
            return fileManager.createFile(
                atPath: url.path(),
                contents: content
            )
        }

        return true
    }

    @discardableResult
    func createFile(
        at url: URL,
        content: Data?,
        overwrite: Bool = true
    ) -> Bool {
        if overwrite {
            return fileManager.createFile(
                atPath: url.path(),
                contents: content
            )
        }

        return true
    }

    func move(from: URL, to: URL) throws -> FileStorageService.Error? {
        do {
            try fileManager.moveItem(at: from, to: to)
            return nil
        } catch {
            return .cantMoveFile(from: from, to: to, reason: error)
        }
    }

    func contents(of url: URL) -> Result<[FileObject], FileStorageService.Error> {
        var result: [FileObject] = .init()

        do {
            let (isExists, isDirectory): (Bool, Bool) = isFileExists(at: url)
            if isExists {
                if isDirectory {
                    let files: [String] = try fileManager.contentsOfDirectory(atPath: url.path(percentEncoded: false))
                    for filename in files {
                        do {
                            let fileURL: URL = url.appendingPathComponent(filename)
                            let object: FileObject = try fetchObject(
                                from: fileURL,
                                name: filename
                            )
                            result.append(object)
                        } catch {
                            log.error(error.localizedDescription)
                        }
                    }
                } else {
                    let filename: String = url.lastPathComponent
                    do {
                        let object: FileObject = try fetchObject(
                            from: url,
                            name: filename
                        )
                        result.append(object)
                    } catch {
                        log.error(error.localizedDescription)
                    }
                }
            } else {
                return .failure(.fileDoesNotExists(url: url))
            }
        } catch {
            return .failure(.some(error: error))
        }

        return .success(result)
    }

    func contents(of file: URL, securityScoped: Bool = false) -> Data? {
        if securityScoped {
            guard file.startAccessingSecurityScopedResource() else {
                log.error("Cannot get permission read file")
                return nil
            }

            defer { file.stopAccessingSecurityScopedResource() }

            return fileManager.contents(atPath: file.path(percentEncoded: false))
        }

        return fileManager.contents(atPath: file.path(percentEncoded: false))
    }

    func deleteObject(at url: URL) -> FileStorageService.Error? {
        do {
            try fileManager.removeItem(at: url)
            return nil
        } catch {
            return .cantRemoveObject(
                url: url,
                reason: error
            )
        }
    }

    func deleteObject(_ object: FileObject) -> FileStorageService.Error? {
        deleteObject(at: object.url)
    }
}

// MARK: - Private Methods
private extension FileStorageService {
    func fetchObject(from url: URL, name: String) throws -> FileObject {
        let attributes: [FileAttributeKey: Any] = try fileManager.attributesOfItem(atPath: url.path(percentEncoded: false))

        guard let creationDate: Date = attributes[.creationDate] as? Date else {
            throw Error.missingData(error: .fileMissingCreationDate(url: url))
        }

        guard let fileType: FileAttributeType = attributes[.type] as? FileAttributeType else {
            throw Error.missingData(error: .fileMissingFileType(url: url))
        }

        guard let size: NSNumber = attributes[.size] as? NSNumber else {
            throw Error.missingData(error: .fileMissingFileSize(url: url))
        }

        var childs: [FileObject] = .init()
        if fileType == .typeDirectory {
            let result: Result<[FileObject], FileStorageService.Error> = contents(of: url)
            switch result {
                case let .success(objects):
                    childs = objects
                case let .failure(error):
                    log.error(error.localizedDescription)
            }
        }

        let object: FileObject = .init(
            id: name,
            url: url,
            creationDate: creationDate,
            fileType: fileType,
            size: size,
            childs: childs
        )

        return object
    }
}
