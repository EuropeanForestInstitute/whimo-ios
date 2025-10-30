//
//  TimeAgoFormatter.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 25.06.2025.
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
import Resources

private typealias Localization = AppLocale.TimeAgoFormatter

final class TimeAgoFormatter: @unchecked Sendable {
    let dateFormatter: DateTimeFormatter = .iso8601

    func timeAgo(from isoString: String) -> String? {
        guard let date = dateFormatter.date(from: isoString) else {
            return nil
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)
        let componentsFormatter = DateComponentsFormatter()
        componentsFormatter.allowedUnits = [
            .year,
            .month,
            .weekOfMonth,
            .day,
            .hour,
            .minute,
            .second
        ]
        componentsFormatter.maximumUnitCount = 1
        componentsFormatter.unitsStyle = .abbreviated
        componentsFormatter.zeroFormattingBehavior = .dropAll

        guard let raw = componentsFormatter.string(from: interval) else {
            return nil
        }

        let withFullMonth = raw.replacingOccurrences(
            of: "mo",
            with: "month",
            options: .regularExpression
        )

        return Localization.ago(withFullMonth)
    }
}
