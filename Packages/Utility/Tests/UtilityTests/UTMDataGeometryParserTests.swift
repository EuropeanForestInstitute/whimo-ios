//
//  UTMDataGeometryParserTests.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 10.07.2025.
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
final class UTMDataGeometryParserTests: XCTestCase {
    private enum TestData {
        static let payload = """
            PROGRAMME D'IDENTIFICATION ET DE GEOLOCALISATION DES PARCELLES DE CACAO

            Nom et Prénoms : MENOUNGA THOMAS. JANVIER
            NIPr :A60000
            NIPa :CELKEV1386.2/2
            Sexe : Masculin
            Numéro de téléphone : 653610999
            Numéro de CNI : /
            Région : CENTRE
            Département : LEKIE
            Arrondissement : EVODOULA
            Village : MINWOHO SUD
            Lieu-dit: MINWOHO SUD
            Coopérative: SOCADYC
            Superficie : 01 ha 14 a 27 ca
            https://www.google.com/maps/search/?api=1&query=4.113264730005791,11.21416465878816
            ([745841.464;454909.449],[745801.921;454949.826],[745769.578;454997.303],[745735.850;455023.426],[745752.374;455072.918],[745757.235;455082.555],[745803.181;455056.245],[745851.383;454977.618],[745893.725;454929.174],[745862.401;454889.596])
        """
    }

    private var parser: UTMDataGeometryParser!
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
            "Empty input string must produce \(UTMDataGeometryParser.Error.cannotRecognize) error."
        )
    }

    func testPoint() throws {
        input = TestData.payload
        let coordinate = try parser.parsePoint(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 4.113264730005791,
            longitude: 11.21416465878816
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

        XCTAssertEqual(coordinates.count, 10)
    }

    func testQRCodeFindFirstCoordinates() throws {
        input = TestData.payload
        let coordinates = try parser.parsePolygon(input)
        let expectedCoordinate: CLLocationCoordinate2D = .init(
            latitude: 4.112553993403083,
            longitude: 11.214430993124376
        )

        XCTAssertEqual(coordinates.first, expectedCoordinate)
    }

    func testQRCodeFindLastCoordinates() throws {
        input = TestData.payload
        let coordinates = try parser.parsePolygon(input)
        let expectedCoordinate: CLLocationCoordinate2D = .init(
            latitude: 4.112373996502038,
            longitude: 11.214618993621015
        )

        XCTAssertEqual(coordinates.last, expectedCoordinate)
    }
}
// swiftlint:enable all
