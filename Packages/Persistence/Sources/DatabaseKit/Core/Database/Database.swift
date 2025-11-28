//
//  Database.swift
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

public protocol Database: AnyObject {
    var reader: any DatabaseReader { get }

    @discardableResult
    func save<T: MutableStorePersistable>(_ model: T) async throws -> T
    func save(_ writeClosure: @escaping (_ db: GRDB.Database) throws -> Void) async throws

    func readAll<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> [T]
    func readOne<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> T?
    func readCount<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> Int
    func find<T: MutableStorePersistable>(_ modelType: T.Type, key: some DatabaseValueConvertible) async throws -> T

    func update<T: MutableStorePersistable>(_ model: T) async throws

    @discardableResult
    func delete<T: MutableStorePersistable>(_ model: T) async throws -> Bool

    func flush() async throws
}

public class PreviewDatabaseImpl: Database {
    public var reader: any DatabaseReader { fatalError("Do not call for preview.") }

    public init() { }

    public func save<T: MutableStorePersistable>(_ model: T) async throws -> T { model }
    public func save(_ writeClosure: @escaping (_ db: GRDB.Database) throws -> Void) async throws { }

    public func readAll<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> [T] { [] }
    public func readOne<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> T? { nil }
    public func readCount<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> Int { .zero }
    public func find<T: MutableStorePersistable>(_ modelType: T.Type, key: some DatabaseValueConvertible) async throws -> T {
        preconditionFailure("Unsupported method")
    }

    public func update<T: MutableStorePersistable>(_ model: T) async throws { }

    @discardableResult
    public func delete<T: MutableStorePersistable>(_ model: T) async throws -> Bool { true }

    public func flush() async throws { }
}
