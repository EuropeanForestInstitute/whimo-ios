//
//  LatLonDataGeometryParserTests.swift
//  WhimoTests
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

import XCTest
import CoreLocation
@testable import Utility

// swiftlint:disable all
final class LatLonDataGeometryParserTests: XCTestCase {
    private enum TestData {
        static let payload = """
            Code Parcelle: CENSMB0023.3/4
            Lieu-dit : MEVA AYAT

            Coordonnées des sommets de la parcelle (Coordonnées géographiques)
            [3.549657,11.547268];[3.549081,11.547502];[3.549055,11.547554];[3.548675,11.547523];[3.548671,11.546779];[3.548937,11.546271];[3.549024,11.546335];[3.549892,11.546541];[3.549974,11.546824];[3.549783,11.547222];[3.549701,11.54735]
        """
    }

    private var parser: LatLonDataGeometryParser!
    private var input: String!

    override func setUpWithError() throws {
        parser = .init()
    }

    override func tearDownWithError() throws {
        parser = nil
        input = nil
    }

    // MARK: - GeoPoint Parsing Tests
    func testEmptyPoint() throws {
        input = ""
        XCTAssertThrowsError(
            try parser.parsePoint(input),
            "Empty input string must produce \(LatLonDataGeometryParser.Error.cannotRecognize) error."
        )
    }

    func testPoint() throws {
        input = TestData.payload
        let coordinate = try parser.parsePoint(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 3.549657,
            longitude: 11.547268
        )

        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate, expectedCoordinates)
    }

    // MARK: - GeoBox Parsing Tests
    func testEmptyGeoBox() throws {
        input = ""
        let coordinates = try parser.parsePolygon(input)

        XCTAssertEqual(coordinates.count, 0)
    }

    func testQRCodeFindAllCoordinates() throws {
        input = TestData.payload
        let coordinates = try parser.parsePolygon(input)

        XCTAssertEqual(coordinates.count, 11)
    }

    func testQRCodeFindFirstCoordinates() throws {
        input = TestData.payload
        let coordinates = try parser.parsePolygon(input)
        let expectedCoordinate: CLLocationCoordinate2D = .init(
            latitude: 3.549657,
            longitude: 11.547268
        )

        XCTAssertEqual(coordinates.first, expectedCoordinate)
    }

    func testQRCodeFindLastCoordinates() throws {
        input = TestData.payload
        let coordinates = try parser.parsePolygon(input)
        let expectedCoordinate: CLLocationCoordinate2D = .init(
            latitude: 3.549701,
            longitude: 11.54735
        )

        XCTAssertEqual(coordinates.last, expectedCoordinate)
    }
}
// swiftlint:enable all
