//
//  DatabaseImpl+Error.swift
//  Database
//
//  Created by Vyacheslav Razumeenko on 01.06.2025.
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

extension DatabaseImpl {
    public enum Error: LocalizedError {
        case failedSaveObject(object: any MutableStorePersistable, reason: Swift.Error)
        case failedSaveObjects(reason: Swift.Error)
        case failedReadObject(reason: Swift.Error)
        case failedReadObjects(reason: Swift.Error)
        case failedUpdateObject(object: any MutableStorePersistable, reason: Swift.Error)
        case failedDeleteObject(object: any MutableStorePersistable, reason: Swift.Error)
        case failedFlushDatabase(reason: Swift.Error)

        public var errorDescription: String? {
            switch self {
                case let .failedSaveObject(object, reason):
                    return "Failed save object: \(object). Reason: \(reason.localizedDescription)"
                case .failedSaveObjects(let reason):
                    return "Failed save objects. Reason: \(reason.localizedDescription)"
                case let .failedReadObject(reason):
                    return "Failed read object. Reason: \(reason.localizedDescription)"
                case let .failedReadObjects(reason):
                    return "Failed read objects. Reason: \(reason.localizedDescription)"
                case let .failedUpdateObject(object, reason):
                    return "Failed update object: \(object). Reason: \(reason.localizedDescription)"
                case let .failedDeleteObject(object, reason):
                    return "Failed delete object: \(object). Reason: \(reason.localizedDescription)"
                case let .failedFlushDatabase(reason):
                    return "Failed flush database. Reason: \(reason.localizedDescription)"
            }
        }
    }
}
