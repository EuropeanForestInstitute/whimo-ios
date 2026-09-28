//
//  TransactionListQuery.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 19.08.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import Utility

struct TransactionListQuery: Equatable {
    var search: String = ""
    var createdAtFrom: Date?
    var createdAtTo: Date?
    var action: TransactionModel.Action?
    var filter = CommoditySeasonFilter()
    var commodityId: String?
    var exactSeasonId: String?
    var newestFirst = false

    func matches(_ transaction: TransactionModel) -> Bool {
        if let commodityId, transaction.commodity.id != commodityId { return false }
        if let exactSeasonId, transaction.harvestSeasonId != exactSeasonId { return false }
        if let groupId = filter.group?.id, transaction.commodity.group.id != groupId { return false }
        if let seasonId = filter.season?.id, transaction.harvestSeasonId != seasonId { return false }
        if let action, transaction.action != action { return false }
        if createdAtFrom != nil || createdAtTo != nil {
            guard let date = transaction.creationDate else { return false }

            if let createdAtFrom, date < createdAtFrom { return false }
            if let createdAtTo, date > createdAtTo { return false }
        }
        return search.isEmpty || transaction.commodity.name.localizedCaseInsensitiveContains(search)
    }

    static func creationOrder(_ transactions: [TransactionModel]) -> [TransactionModel] {
        let dated = transactions.map { (transaction: $0, date: $0.creationDate ?? Date.distantPast) }
        let ordered = dated.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.transaction.id < rhs.transaction.id }
            return lhs.date > rhs.date
        }
        return ordered.map(\.transaction)
    }
}

extension TransactionModel {
    var creationDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: createdAt) { return date }
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: createdAt)
    }
}

struct TransactionListPage {
    let list: IdentifiedArrayOf<TransactionModel>
    let nextPage: Int?
    let isCached: Bool
}
