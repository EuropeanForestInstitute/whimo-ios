//
//  UTMDataGeometryParser.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.06.2025.
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
import UTMConversion

public final class UTMDataGeometryParser: AnyGeometryParser {
    enum Constants {
        enum CICCParsing {
            static let ciccFileHeader = "PROGRAMME D'IDENTIFICATION ET DE GEOLOCALISATION DES PARCELLES DE CACAO"
            static let googleMapsKey = "https://www.google.com/maps/search/"
        }

        static let eastingKey = "easting"
        static let northingKey = "northing"
        static let pattern = #"""
        (?x)                                                # Enable extended mode with comments
        (?<\#(Constants.eastingKey)>\d{5,7}(?:\.\d+)?)      # UTM easting: 5–7 digits integer part with optional fractional part
        (?:\s*;\s*)                                         # Separator: semicolon with optional surrounding spaces
        (?<\#(Constants.northingKey)>\d{5,7}(?:\.\d+)?)     # UTM northing: 5–7 digits integer part with optional fractional part
        """#
    }

    public enum Error: LocalizedError {
        case cannotRecognize
    }

    // MARK: - Init
    public init() { }

    // MARK: - Public Methods
    public func parsePoint(_ stringData: String) throws -> CLLocationCoordinate2D {
        let lines = stringData.split(separator: "\n")
        let ciccFileHeader = Constants.CICCParsing.ciccFileHeader

        for line in lines where line.contains(ciccFileHeader) {
            return try parseCICCFile(stringData)
        }

        throw Error.cannotRecognize
    }

    public func parsePolygon(_ text: String) throws -> [CLLocationCoordinate2D] {
        let pointCoordinate: CLLocationCoordinate2D
        do {
            pointCoordinate = try parsePoint(text)
        } catch {
            return []
        }

        let pointUTMCoordinate = pointCoordinate.utmCoordinate()
        let regex: NSRegularExpression = try .init(pattern: Constants.pattern, options: [.allowCommentsAndWhitespace])
        let fullRange: NSRange = .init(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: fullRange)
        let coordinates: [CLLocationCoordinate2D] = matches
            .map { getCoordinate(from: text, match: $0, controlPoint: pointUTMCoordinate) }
            .compactMap { $0 }

        return coordinates
    }
}

// MARK: - Private Methods
private extension UTMDataGeometryParser {
    func parseCICCFile(_ stringData: String) throws -> CLLocationCoordinate2D {
        let returnWithThrowing: () throws -> CLLocationCoordinate2D = { throw Error.cannotRecognize }
        let lines = stringData.split(separator: "\n")
        let googleMapsKey = Constants.CICCParsing.googleMapsKey

        for line in lines where line.contains(googleMapsKey) {
            let googleMapsStringUrl = line.trimmingCharacters(in: .whitespaces)
            guard let googleMapsUrl: URL = .init(string: googleMapsStringUrl) else {
                log.debug("Founded string url is not valid url: \(googleMapsStringUrl)")
                return try returnWithThrowing()
            }

            let components = URLComponents(url: googleMapsUrl, resolvingAgainstBaseURL: true)
            let stringCoordinates = components?.queryItems?.last?.value?.removingPercentEncoding ?? ""
            let coordinatePaths = stringCoordinates.split(separator: ",")
            guard coordinatePaths.count == 2 else {
                log.error("Coordinates cannot be found.")
                return try returnWithThrowing()
            }

            let latitude = coordinatePaths[0]
            let longitude = coordinatePaths[1]

            let coordinates: CLLocationCoordinate2D = .init(
                latitude: Double(latitude) ?? .zero,
                longitude: Double(longitude) ?? .zero
            )
            return coordinates
        }

        return try returnWithThrowing()
    }

    func getCoordinate(from text: String, match: NSTextCheckingResult, controlPoint: UTMCoordinate) -> CLLocationCoordinate2D? {
        // swiftlint:disable identifier_name
        guard
            let eastingString = Range(match.range(withName: Constants.eastingKey), in: text),
            let northingString = Range(match.range(withName: Constants.northingKey), in: text),
            let easting = Double(text[eastingString]),
            let northing = Double(text[northingString])
        else { return nil }
        // swiftlint:enable identifier_name

        let coordinate: UTMCoordinate = .init(
            northing: northing,
            easting: easting,
            zone: controlPoint.zone,
            hemisphere: controlPoint.hemisphere
        )
        return coordinate.coordinate()
    }
}
