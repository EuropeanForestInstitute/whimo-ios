//
//  LatLonDataGeometryParser.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 08.09.2025.
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
import struct CoreLocation.CLLocationCoordinate2D

// MARK: - LatLonDataGeometryParser
public final class LatLonDataGeometryParser: AnyGeometryParser {
    private enum Constants {
        static let latitudeKey = "lat"
        static let longitudeKey = "lon"
        static let pattern = #"""
        (?x)                                                   # Enable extended mode with comments
        (?<\#(Constants.latitudeKey)>-?\d{1,2}(?:\.\d+)?)      # Latitude easting: 1–2 digits integer part with optional fractional part
        (?:\s*,\s*)                                            # Separator: semicolon with optional surrounding spaces
        (?<\#(Constants.longitudeKey)>-?\d{1,2}(?:\.\d+)?)     # Longitude northing: 1–2 digits integer part with optional fractional part
        """#
    }

    // MARK: - Error
    public enum Error: LocalizedError {
        case cannotRecognize
    }

    // MARK: - Init
    public init() { }

    // MARK: - Public Methods
    public func parsePoint(_ text: String) throws -> CLLocationCoordinate2D {
        let regex: NSRegularExpression = try .init(pattern: Constants.pattern, options: [.allowCommentsAndWhitespace])
        let fullRange: NSRange = .init(text.startIndex..<text.endIndex, in: text)

        let matches = regex.matches(in: text, range: fullRange)
        guard
            let firstMatch = matches.first,
            let coordinate = getCoordinate(from: text, match: firstMatch)
        else { throw Error.cannotRecognize }

        return coordinate
    }

    public func parsePolygon(_ text: String) throws -> [CLLocationCoordinate2D] {
        let regex: NSRegularExpression = try .init(pattern: Constants.pattern, options: [.allowCommentsAndWhitespace])
        let fullRange: NSRange = .init(text.startIndex..<text.endIndex, in: text)

        let matches = regex.matches(in: text, range: fullRange)
        let coordinates: [CLLocationCoordinate2D] = matches
            .map { getCoordinate(from: text, match: $0) }
            .compactMap { $0 }

        return coordinates
    }
}

// MARK: - Private Methods
private extension LatLonDataGeometryParser {
    func getCoordinate(from text: String, match: NSTextCheckingResult) -> CLLocationCoordinate2D? {
        guard
            let latString = Range(match.range(withName: Constants.latitudeKey), in: text),
            let lonString = Range(match.range(withName: Constants.longitudeKey), in: text),
            let lat = Double(text[latString]),
            let lon = Double(text[lonString])
        else { return nil }

        let coordinate: CLLocationCoordinate2D = .init(latitude: lat, longitude: lon)
        return coordinate
    }
}
