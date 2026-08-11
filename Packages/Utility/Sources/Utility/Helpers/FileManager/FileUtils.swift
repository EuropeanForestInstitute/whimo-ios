//
//  FileUtils.swift
//  Utility
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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

// MARK: - FileUtils
public enum FileUtils {
    private enum Constants {
        enum Database {
            static let folderName = "database"
            static let fileName = "database"
            static let fileExtension = "sqlite"
        }

        enum QRCodeFiles {
            static let fileName = "map-areas"
            static let fileExtension = "geojson"
        }

        enum Downloads {
            static let folderName = "downloads"
        }
    }

    // MARK: - Public Properties
    public static var documentsDirectory: FileManager.SearchPathDirectory { .documentDirectory }
    public static var directoryURL: URL {
        // swiftlint:disable:next force_unwrapping
        FileUtils.fileManager.urls(for: documentsDirectory, in: .userDomainMask).first!
    }

    // MARK: - Private Properties
    private static var fileManager: FileManager { FileManager.default }
}

// MARK: - FileUtils+Database
extension FileUtils {
    public enum Database {
        private typealias Path = Constants.Database

        public static var fileExtension: String { Path.fileExtension }
        public static var directoryURL: URL { FileUtils.directoryURL.appendingPathComponent(Path.folderName) }
        public static var fileURL: URL { directoryURL.appendingPathComponent("\(Path.fileName).\(Path.fileExtension)") }
    }
}

// MARK: - FileUtils+QRCodeFiles
extension FileUtils {
    public enum QRCodeFiles {
        private typealias Path = Constants.QRCodeFiles

        public static var fileExtension: String { Path.fileExtension }
        public static var temporaryDirectoryURL: URL { FileUtils.fileManager.temporaryDirectory }
        public static var temporaryFileURL: URL { temporaryDirectoryURL.appendingPathComponent("\(Path.fileName).\(Path.fileExtension)") }
    }
}

// MARK: - FileUtils+Downloads
extension FileUtils {
    public enum Downloads {
        private typealias Path = Constants.Downloads

        public static var directoryURL: URL { FileUtils.directoryURL.appendingPathComponent(Path.folderName) }
        public static var temporaryDirectoryURL: URL { FileUtils.fileManager.temporaryDirectory }
    }
}
