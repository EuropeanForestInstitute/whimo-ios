//
//  CreationSeason.swift
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

struct CreationSeason: Equatable {
    let commodityId: String
    let season: HarvestSeason
}

enum CreationSeasonError: Error {
    case catalogueRequired
    case invalidSelection
}

/// Client creation guard; acceptance and Automatic adjustments remain backend-owned.
enum SeasonalSaleValidation: Equatable {
    case invalidSelection
    case invalidQuantity
    case balanceUnavailable
    case sufficient
    case activeShortage
    case seasonalShortage

    init(volume: String, season: HarvestSeason?, balance: ExactSeasonalBalance?) {
        guard let quantity = Double(volume), quantity.isFinite, quantity >= 0 else {
            self = .invalidQuantity
            return
        }
        guard let season else {
            self = .invalidSelection
            return
        }
        guard let balance, balance.volume.isFinite, balance.volume >= 0 else {
            self = .balanceUnavailable
            return
        }
        if quantity <= balance.volume {
            self = .sufficient
        } else {
            self = season.status == .active ? .activeShortage : .seasonalShortage
        }
    }

    var permitsSale: Bool { self == .sufficient || self == .activeShortage || self == .balanceUnavailable }
}

enum SeasonalSaleError: Error {
    case invalidQuantity
    case insufficientBalance(HarvestSeason)
}

/// Transient exact balance for a seller draft; never part of a transaction request or offline record.
struct ConfirmedSeasonalBalance: Equatable {
    let commodityId: String
    let seasonId: String
    let balance: ExactSeasonalBalance
}
