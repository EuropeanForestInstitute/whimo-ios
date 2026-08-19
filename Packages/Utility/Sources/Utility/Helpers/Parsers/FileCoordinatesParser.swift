//
//  FileCoordinatesParser.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 16.06.2025.
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
import CoreLocation

public struct FileCoordinatesParser {
    public init() { }

    public func parse(_ text: String) throws -> [CLLocationCoordinate2D] {
        // Search pattern:
        // - latitude: -90 to +90, up to 2 digits integer part and fractional part
        // - longitude: -180 to +180, up to 3 digits integer part and fractional part
        let pattern = #"""
        (?x)                             # Enable extended mode with comments
        (?<lat>[-+]?\d{1,2}(?:\.\d+)?)   # Latitude: ±dd(.dddd)?
        (?:\s*,\s*|\s+)                  # Separator: comma or whitespace
        (?<lon>[-+]?\d{1,3}(?:\.\d+)?)   # Longitude: ±ddd(.dddd)?
        """#

        let regex: NSRegularExpression = try .init(pattern: pattern, options: [.allowCommentsAndWhitespace])
        let fullRange: NSRange = .init(text.startIndex..<text.endIndex, in: text)

        let matches = regex.matches(in: text, range: fullRange)
        var coordinates: [CLLocationCoordinate2D] = []

        for match in matches {
            guard
                let rLat: Range = .init(match.range(withName: "lat"), in: text),
                let rLon: Range = .init(match.range(withName: "lon"), in: text),
                let lat = Double(text[rLat]),
                let lon = Double(text[rLon])
            else {
                continue
            }
            coordinates.append(.init(latitude: lat, longitude: lon))
        }

        return coordinates
    }
}
