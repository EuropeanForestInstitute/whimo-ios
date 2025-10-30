//
//  FileCoordinatesParserTests.swift
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

import XCTest
import CoreLocation
@testable import Utility

final class FileCoordinatesParserTests: XCTestCase {
    private enum TestData {
        // swiftlint:disable all
        static let csvFile: String = """
                "system:index","geometry","name","whisp_plotId","whisp_external_id","whisp_Area","whisp_Geometry_type","whisp_Country","whisp_ProducerCountry","whisp_Admin_Level_1","whisp_Centroid_lon","whisp_Centroid_lat","whisp_Unit","whisp_In_waterbody","whisp_EUFO_2020","whisp_GLAD_Primary","whisp_TMF_undist","whisp_JAXA_FNF_2020","whisp_GFC_TC_2020","whisp_Forest_FDaP","whisp_ESA_TC_2020","whisp_TMF_plant","whisp_Oil_palm_Descals","whisp_Oil_palm_FDaP","whisp_Cocoa_FDaP","whisp_Cocoa_ETH","whisp_Cocoa_bnetd","whisp_Rubber_FDaP","whisp_Rubber_RBGE","whisp_TMF_def_2000","whisp_TMF_def_2001","whisp_TMF_def_2002","whisp_TMF_def_2003","whisp_TMF_def_2004","whisp_TMF_def_2005","whisp_TMF_def_2006","whisp_TMF_def_2007","whisp_TMF_def_2008","whisp_TMF_def_2009","whisp_TMF_def_2010","whisp_TMF_def_2011","whisp_TMF_def_2012","whisp_TMF_def_2013","whisp_TMF_def_2014","whisp_TMF_def_2015","whisp_TMF_def_2016","whisp_TMF_def_2017","whisp_TMF_def_2018","whisp_TMF_def_2019","whisp_TMF_def_2020","whisp_TMF_def_2021","whisp_TMF_def_2022","whisp_TMF_def_2023","whisp_TMF_deg_2000","whisp_TMF_deg_2001","whisp_TMF_deg_2002","whisp_TMF_deg_2003","whisp_TMF_deg_2004","whisp_TMF_deg_2005","whisp_TMF_deg_2006","whisp_TMF_deg_2007","whisp_TMF_deg_2008","whisp_TMF_deg_2009","whisp_TMF_deg_2010","whisp_TMF_deg_2011","whisp_TMF_deg_2012","whisp_TMF_deg_2013","whisp_TMF_deg_2014","whisp_TMF_deg_2015","whisp_TMF_deg_2016","whisp_TMF_deg_2017","whisp_TMF_deg_2018","whisp_TMF_deg_2019","whisp_TMF_deg_2020","whisp_TMF_deg_2021","whisp_TMF_deg_2022","whisp_TMF_deg_2023","whisp_GFC_loss_year_2001","whisp_GFC_loss_year_2002","whisp_GFC_loss_year_2003","whisp_GFC_loss_year_2004","whisp_GFC_loss_year_2005","whisp_GFC_loss_year_2006","whisp_GFC_loss_year_2007","whisp_GFC_loss_year_2008","whisp_GFC_loss_year_2009","whisp_GFC_loss_year_2010","whisp_GFC_loss_year_2011","whisp_GFC_loss_year_2012","whisp_GFC_loss_year_2013","whisp_GFC_loss_year_2014","whisp_GFC_loss_year_2015","whisp_GFC_loss_year_2016","whisp_GFC_loss_year_2017","whisp_GFC_loss_year_2018","whisp_GFC_loss_year_2019","whisp_GFC_loss_year_2020","whisp_GFC_loss_year_2021","whisp_GFC_loss_year_2022","whisp_GFC_loss_year_2023","whisp_RADD_year_2019","whisp_RADD_year_2020","whisp_RADD_year_2021","whisp_RADD_year_2022","whisp_RADD_year_2023","whisp_RADD_year_2024","whisp_RADD_year_2025","whisp_ESA_fire_2001","whisp_ESA_fire_2002","whisp_ESA_fire_2003","whisp_ESA_fire_2004","whisp_ESA_fire_2005","whisp_ESA_fire_2006","whisp_ESA_fire_2007","whisp_ESA_fire_2008","whisp_ESA_fire_2009","whisp_ESA_fire_2010","whisp_ESA_fire_2011","whisp_ESA_fire_2012","whisp_ESA_fire_2013","whisp_ESA_fire_2014","whisp_ESA_fire_2015","whisp_ESA_fire_2016","whisp_ESA_fire_2017","whisp_ESA_fire_2018","whisp_ESA_fire_2019","whisp_ESA_fire_2020","whisp_MODIS_fire_2000","whisp_MODIS_fire_2001","whisp_MODIS_fire_2002","whisp_MODIS_fire_2003","whisp_MODIS_fire_2004","whisp_MODIS_fire_2005","whisp_MODIS_fire_2006","whisp_MODIS_fire_2007","whisp_MODIS_fire_2008","whisp_MODIS_fire_2009","whisp_MODIS_fire_2010","whisp_MODIS_fire_2011","whisp_MODIS_fire_2012","whisp_MODIS_fire_2013","whisp_MODIS_fire_2014","whisp_MODIS_fire_2015","whisp_MODIS_fire_2016","whisp_MODIS_fire_2017","whisp_MODIS_fire_2018","whisp_MODIS_fire_2019","whisp_MODIS_fire_2020","whisp_MODIS_fire_2021","whisp_MODIS_fire_2022","whisp_MODIS_fire_2023","whisp_MODIS_fire_2024","whisp_TMF_deg_before_2020","whisp_TMF_def_before_2020","whisp_GFC_loss_before_2020","whisp_ESA_fire_before_2020","whisp_MODIS_fire_before_2020","whisp_RADD_before_2020","whisp_TMF_deg_after_2020","whisp_TMF_def_after_2020","whisp_GFC_loss_after_2020","whisp_MODIS_fire_after_2020","whisp_RADD_after_2020","whisp_geojson","whisp_Indicator_1_treecover","whisp_Indicator_2_commodities","whisp_Indicator_3_disturbance_before_2020","whisp_Indicator_4_disturbance_after_2020","whisp_EUDR_risk","data:Walk around and map a polygon","data:How much is 2+3","data:contributor_name","data:contributor_email","data:created_client_timestamp","data:created_server_timestamp"
                "","POLYGON ((74.60736136883497 42.81718512134488, 74.60702039301395 42.81803555447452, 74.60510764271021 42.81805547483275, 74.60503187030554 42.816851388318014, 74.60736136883497 42.81718512134488))","Aisas farm","1",,1.9980000257492065,"Polygon","KGZ","KG","Chuy Region",74.60607777805608,42.81750917971891,"ha","false",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"{""type"":""Polygon"",""coordinates"":[[[74.60503200000109,42.816850999995815],[74.60736100000057,42.81718499999649],[74.6070200000038,42.8180359999995],[74.60510799999838,42.818054999996576],[74.60503200000109,42.816850999995815]]]}","no","no","no","no","low",,"5","Aisalkyn Tashmatova","aisalkyn_t@maddevs.io","2025-05-20T12:35:59.000Z","2025-05-20T12:35:59.000Z"
        """

        static let geojsonFile: String = """
        {
          "type": "FeatureCollection",
          "features": [
            {
          "type": "Feature",
          "properties": {
            "whisp_Indicator_2_commodities": "no",
            "whisp_Indicator_3_disturbance_before_2020": "no",
            "whisp_plotId": "1",
            "whisp_EUDR_risk": "low",
            "whisp_In_waterbody": "false",
            "whisp_Centroid_lat": 42.818246203132794,
            "name": "MD test farm",
            "whisp_Country": "KGZ",
            "whisp_Unit": "ha",
            "whisp_geojson": "{\"type\":\"Polygon\",\"coordinates\":[[[74.6043539999989,42.81763200000202],[74.6046519999966,42.81742699999854],[74.60457100000338,42.816931000002434],[74.60490999999998,42.816738999995536],[74.60604699999969,42.81665699999774],[74.60709000000061,42.816876000002374],[74.60743800000245,42.817066000000125],[74.60692500000044,42.81874600000432],[74.60642799999977,42.82000499999616],[74.6046579999971,42.81989600000062],[74.60439000000189,42.81852600000409],[74.6043539999989,42.81763200000202]]]}",
            "whisp_Indicator_1_treecover": "no",
            "whisp_Indicator_4_disturbance_after_2020": "no",
            "whisp_Centroid_lon": 74.60576349157252,
            "whisp_Area": 7.275000095367432,
            "whisp_ProducerCountry": "KG",
            "whisp_Admin_Level_1": "Chuy Region",
            "whisp_Geometry_type": "Polygon"
          },
          "geometry": {
            "type": "Polygon",
            "coordinates": [
              [
                [
                  74.60743814706802,
                  42.817066335219735
                ],
                [
                  74.60692517459393,
                  42.81874604328349
                ],
                [
                  74.60642829537392,
                  42.8200046877363
                ],
                [
                  74.60465837270021,
                  42.819895743947946
                ],
                [
                  74.60439015179873,
                  42.81852642958048
                ],
                [
                  74.6043536067009,
                  42.81763198139089
                ],
                [
                  74.60465166717768,
                  42.81742736563414
                ],
                [
                  74.60457120090723,
                  42.81693057936873
                ],
                [
                  74.60490982979536,
                  42.81673899587626
                ],
                [
                  74.6060474216938,
                  42.81665709928569
                ],
                [
                  74.60709046572447,
                  42.816875981822875
                ],
                [
                  74.60743814706802,
                  42.817066335219735
                ]
              ]
            ]
          }
        }
          ]
        }
        """
        // swiftlint:enable all
    }

    private var parser: FileCoordinatesParser!
    private var input: String!

    override func setUpWithError() throws {
        parser = .init()
    }

    override func tearDownWithError() throws {
        parser = nil
        input = nil
    }

    func testEmptyFile() throws {
        input = ""
        let coordinates = try parser.parse(input)

        XCTAssertEqual(coordinates.count, 0)
    }

    func testCSVFindAllCoordinates() throws {
        input = TestData.csvFile
        let coordinates = try parser.parse(input)

        XCTAssertEqual(coordinates.count, 11)
    }

    func testCSVFindFirstCoordinates() throws {
        input = TestData.csvFile
        let coordinates = try parser.parse(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 74.60736136883497,
            longitude: 42.81718512134488
        )

        XCTAssertEqual(coordinates.first, expectedCoordinates)
    }

    func testCSVFindLastCoordinates() throws {
        input = TestData.csvFile
        let coordinates = try parser.parse(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 74.60503200000109,
            longitude: 42.816850999995815
        )

        XCTAssertEqual(coordinates.last, expectedCoordinates)
    }

    func testGEOJSONFindAllCoordinates() throws {
        input = TestData.geojsonFile
        let coordinates = try parser.parse(input)

        XCTAssertEqual(coordinates.count, 24)
    }

    func testGEOJSONFindFirstCoordinates() throws {
        input = TestData.geojsonFile
        let coordinates = try parser.parse(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 74.6043539999989,
            longitude: 42.81763200000202
        )

        XCTAssertEqual(coordinates.first, expectedCoordinates)
    }

    func testGEOJSONFindLastCoordinates() throws {
        input = TestData.geojsonFile
        let coordinates = try parser.parse(input)
        let expectedCoordinates: CLLocationCoordinate2D = .init(
            latitude: 74.60743814706802,
            longitude: 42.817066335219735
        )

        XCTAssertEqual(coordinates.last, expectedCoordinates)
    }
}
