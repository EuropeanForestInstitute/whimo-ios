//
//  DatabaseImpl.swift
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

public final class DatabaseImpl: Database {
    // MARK: - Public Properties
    public var reader: any DatabaseReader { writer }

    // MARK: - Private Properties
    private let writer: any DatabaseWriter

    // MARK: - Init
    public init(writer: any DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }

    // MARK: - Database
    // MARK: - CRUD
    @discardableResult
    public func save<T: MutableStorePersistable>(_ model: T) async throws -> T {
        do {
            return try await writer.write { db in
                try model.saved(db)
            }
        } catch {
            let error = Error.failedSaveObject(object: model, reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func save(_ writeClosure: @escaping (_ db: GRDB.Database) throws -> Void) async throws {
        do {
            return try await writer.write { db in
                try writeClosure(db)
            }
        } catch {
            let error = Error.failedSaveObjects(reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func readAll<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> [T] {
        do {
            return try await reader.read { db in
                try request.fetchAll(db)
            }
        } catch {
            let error = Error.failedReadObjects(reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func readOne<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> T? {
        do {
            return try await reader.read { db in
                try request.fetchOne(db)
            }
        } catch {
            let error = Error.failedReadObject(reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func readCount<T: StoreDecodable>(_ request: QueryInterfaceRequest<T>) async throws -> Int {
        do {
            return try await reader.read { db in
                try request.fetchCount(db)
            }
        } catch {
            let error = Error.failedReadObject(reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func find<T: MutableStorePersistable>(_ modelType: T.Type, key: some DatabaseValueConvertible) async throws -> T {
        do {
            return try await writer.write { db in
                try T.find(db, key: key)
            }
        } catch {
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func update<T: MutableStorePersistable>(_ model: T) async throws {
        do {
            try await writer.write { db in
                try model.update(db)
            }
        } catch {
            let error = Error.failedUpdateObject(object: model, reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    @discardableResult
    public func delete<T: MutableStorePersistable>(_ model: T) async throws -> Bool {
        do {
            return try await writer.write { db in
                try model.delete(db)
            }
        } catch {
            let error = Error.failedDeleteObject(object: model, reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }

    public func flush() async throws {
        do {
            try await writer.write { db in
                let deletableTypes: [any MutableStorePersistable.Type] = [
                    Notification.self,
                    TransactionTraceability.self,
                    Transaction.self,
                    User.self,
                    Commodity.self,
                    CommodityGroup.self,
                    NotificationsSettings.self
                ]

                for deletableType in deletableTypes {
                    try deletableType.deleteAll(db)
                }
            }
        } catch {
            let error = Error.failedFlushDatabase(reason: error)
            databaseLog.error(error.localizedDescription)
            throw error
        }
    }
}
