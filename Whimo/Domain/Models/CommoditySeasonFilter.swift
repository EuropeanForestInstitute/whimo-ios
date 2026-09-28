//
//  CommoditySeasonFilter.swift
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

struct CatalogueGroup: DomainModel, Codable {
    let id: String
    let name: String
}

struct CommoditySeasonFilter: Equatable {
    private(set) var group: CatalogueGroup?
    private(set) var season: HarvestSeason?

    init(group: CatalogueGroup? = nil, season: HarvestSeason? = nil) {
        self.group = group
        self.season = group == nil ? nil : season
    }

    var isEmpty: Bool { group == nil }
    var title: String { [group?.name, season?.name].compactMap { $0 }.joined(separator: ", ") }

    mutating func selectGroup(_ group: CatalogueGroup?) {
        guard self.group?.id != group?.id else { return }

        self.group = group
        season = nil
    }

    mutating func selectSeason(_ season: HarvestSeason?) {
        self.season = group == nil ? nil : season
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.group?.id == rhs.group?.id && lhs.season?.id == rhs.season?.id
    }
}

struct CatalogueResult<Value> {
    let values: [Value]
    let isCached: Bool
}
