//
//  DatabaseImpl+Persistence.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 31.05.2025.
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
import GRDB
import enum Utility.FileUtils

extension DatabaseImpl {
    /// Initialize database with default path.
    public convenience init() throws {
        let fileManager: FileManager = .default
        let directoryUrl = FileUtils.Database.directoryURL
        databaseLog.debug("directoryUrl: \(directoryUrl)")
        try fileManager.createDirectory(at: directoryUrl, withIntermediateDirectories: true)

        let databaseURL = FileUtils.Database.fileURL
        let configuration = DatabaseImpl.makeConfiguration()
        let writer = try DatabasePool(path: databaseURL.path(), configuration: configuration)
        try self.init(writer: writer)
    }
}
