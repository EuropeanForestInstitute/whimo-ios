//
//  DatabaseImpl+Migrator.swift
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

private typealias Table = DatabaseTable

extension DatabaseImpl {
    var migrator: DatabaseMigrator {
        var migrator: DatabaseMigrator = .init()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("create_commodity_group") { db in
            try db.create(table: Table.get(.commodityGroup)) { table in
                table.column("id", .text).primaryKey()
                table.column("name", .text).notNull()
            }
        }

        migrator.registerMigration("create_commodity") { db in
            try db.create(table: Table.get(.commodity)) { table in
                table.column("id", .text).primaryKey()
                table.column("code", .text).notNull()
                table.column("name", .text).notNull()
                table.column("unit", .text).notNull()
                table.column("balance", .double)
                table.column("hasRecipe", .boolean).notNull()
                table.belongsTo(Table.get(.commodityGroup), onDelete: .cascade).notNull()
            }
        }

        migrator.registerMigration("create_user") { db in
            try db.create(table: Table.get(.user)) { table in
                table.column("id", .text).primaryKey()
                table.column("username", .text).notNull()
                table.column("gadgets", .jsonText)
            }
        }

        migrator.registerMigration("create_transaction") { db in
            try db.create(table: Table.get(.transaction)) { table in
                table.column("id", .text).primaryKey()
                table.column("createdAt", .text).notNull()
                table.column("expiresAt", .text)
                table.column("updatedAt", .text)

                table.column("type", .jsonText).notNull()
                table.column("status", .text).notNull()
                table.column("action", .text).notNull()
                table.column("traceability", .text)
                table.column("location", .text)
                table.column("farmLatitude", .double)
                table.column("farmLongitude", .double)
                table.column("transactionLatitude", .double)
                table.column("transactionLongitude", .double)
                table.column("volume", .double).notNull()
                table.column("isBuyingFromFarmer", .boolean).notNull()
                table.belongsTo(Table.get(.commodity)).notNull()
                table.belongsTo("seller", inTable: "user")
                table.belongsTo("buyer", inTable: "user")
                table.column("createdById", .text)
                table.column("persistingData", .jsonText).notNull()
            }
        }

        migrator.registerMigration("create_transaction_traceability") { db in
            try db.create(table: Table.get(.transactionTraceability)) { table in
                table.column("id", .integer).primaryKey()
                table.column("items", .jsonText)
                table.belongsTo(Table.get(.transaction), onDelete: .cascade).notNull()
            }
        }

        migrator.registerMigration("create_notification") { db in
            try db.create(table: Table.get(.notification)) { table in
                table.column("id", .text).primaryKey()
                table.column("createdAt", .text).notNull()
                table.column("type", .text).notNull()
                table.column("status", .text).notNull()
                table.column("transactionNode", .jsonText)
            }
        }

        migrator.registerMigration("create_notifications_settings") { db in
            try db.create(table: Table.get(.notificationsSettings)) { table in
                table.column("id", .text).primaryKey()
                table.column("type", .text).notNull()
                table.column("isEnabled", .boolean).notNull()
            }
        }

        return migrator
    }
}
