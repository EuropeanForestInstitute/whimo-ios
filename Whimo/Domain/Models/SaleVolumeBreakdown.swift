//
//  SaleVolumeBreakdown.swift
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

struct SaleVolumeBreakdown: Equatable {
    let seasonVolume: String
    let automaticVolume: String

    var showsSeason: Bool { seasonVolume != "0" || !showsAutomatic }
    var showsAutomatic: Bool { automaticVolume != "0" }

    init?(volume: String, season: HarvestSeason, balance: ExactSeasonalBalance) {
        guard SeasonalSaleValidation(volume: volume, season: season, balance: balance).permitsSale,
              let requested = VolumeDigits(volume), let available = VolumeDigits(balance.volume) else { return nil }

        if requested <= available {
            seasonVolume = requested.description
            automaticVolume = "0"
        } else {
            guard season.status == .active else { return nil }

            seasonVolume = available.description
            automaticVolume = requested.subtracting(available)
        }
    }
}

/// Lossless decimal digits for the Volume editor's decimal-only input grammar.
/// Foundation Decimal would truncate entered quantities beyond its fixed significand capacity.
private struct VolumeDigits: Comparable {
    let integer: String
    let fraction: String

    var description: String { fraction.isEmpty ? integer : integer + "." + fraction }

    init?(_ text: String) {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count),
              text.utf8.allSatisfy({ (48...57).contains($0) || $0 == 46 }),
              text.utf8.contains(where: { (48...57).contains($0) }) else { return nil }

        let whole = parts[0].drop(while: { $0 == "0" })
        integer = whole.isEmpty ? "0" : String(whole)
        fraction = parts.count == 2 ? String(parts[1].reversed().drop(while: { $0 == "0" }).reversed()) : ""
    }

    init?(_ value: Double) {
        if value == 0 {
            self.init("0")
            return
        }
        // A finite backend Double's shortest decimal representation has at most 17 significant digits.
        let parts = String(value).lowercased().split(separator: "e")
        guard parts.count == 2, let exponent = Int(parts[1]) else {
            self.init(String(value))
            return
        }
        let mantissa = String(parts[0])
        let digits = mantissa.replacingOccurrences(of: ".", with: "")
        let integerCount = mantissa.prefix(while: { $0 != "." }).count + exponent
        let expanded: String
        if integerCount <= 0 {
            expanded = "0." + String(repeating: "0", count: -integerCount) + digits
        } else if integerCount >= digits.count {
            expanded = digits + String(repeating: "0", count: integerCount - digits.count)
        } else {
            let split = digits.index(digits.startIndex, offsetBy: integerCount)
            expanded = String(digits[..<split]) + "." + String(digits[split...])
        }
        self.init(expanded)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.integer.count != rhs.integer.count { return lhs.integer.count < rhs.integer.count }
        if lhs.integer != rhs.integer { return lhs.integer < rhs.integer }
        let count = max(lhs.fraction.count, rhs.fraction.count)
        return lhs.fraction.padding(toLength: count, withPad: "0", startingAt: 0)
            < rhs.fraction.padding(toLength: count, withPad: "0", startingAt: 0)
    }

    /// The caller guarantees self > other. Work from the least significant digit with a decimal borrow.
    func subtracting(_ other: Self) -> String {
        let scale = max(fraction.count, other.fraction.count)
        let width = max(integer.count, other.integer.count)
        let left = alignedDigits(width: width, scale: scale)
        let right = other.alignedDigits(width: width, scale: scale)
        var result = [UInt8](repeating: 48, count: left.count)
        var borrow = 0
        for index in left.indices.reversed() {
            var digit = Int(left[index]) - Int(right[index]) - borrow
            borrow = digit < 0 ? 1 : 0
            if digit < 0 { digit += 10 }
            result[index] = UInt8(digit + 48)
        }
        let whole = result.prefix(width).drop(while: { $0 == 48 })
        let fractional = result.suffix(scale).reversed().drop(while: { $0 == 48 }).reversed()
        let integerText = whole.isEmpty ? "0" : whole.map { String($0 - 48) }.joined()
        return fractional.isEmpty ? integerText : integerText + "." + fractional.map { String($0 - 48) }.joined()
    }

    private func alignedDigits(width: Int, scale: Int) -> [UInt8] {
        Array((String(repeating: "0", count: width - integer.count) + integer
            + fraction.padding(toLength: scale, withPad: "0", startingAt: 0)).utf8)
    }
}
