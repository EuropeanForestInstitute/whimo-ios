//
//  QRCodeDataServiceImpl.swift
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

import Foundation
import struct CoreLocation.CLLocationCoordinate2D
import Utility

// MARK: - QRCodeDataServiceImpl
final class QRCodeDataServiceImpl: QRCodeDataService {
    struct FarmInfo {
        let locationPoint: CLLocationCoordinate2D
        let geojson: GeoJSON<PolygonGeometry>
    }

    // MARK: - Dependencies
    private let utmDataGeometryParser: UTMDataGeometryParser = .init()
    private let latLonGeometryParser: LatLonDataGeometryParser = .init()
    private let fileStorage: any FileStorageServiceProtocol

    // MARK: - Init
    init(fileStorage: any FileStorageServiceProtocol) {
        self.fileStorage = fileStorage
    }

    // MARK: - QRCodeDataService
    func getFarmInfo(from rawString: String) throws -> FarmInfo {
        let farmInfoStack = [
            _getFarmInfo(utmRawString:),
            _getFarmInfo(latLonRawString:)
        ]
        var farmInfo: FarmInfo?
        for getFarmInfoFunc in farmInfoStack where farmInfo == nil {
            log.debug("--> started get farm info function")
            let result = getFarmInfoFunc(rawString)
            switch result {
                case .success(let success):
                    farmInfo = success
                case .failure(let error):
                    log.error(error.localizedDescription)
            }
            log.debug("<-- ended get farm info function")
        }
        guard let farmInfo else { throw Error.cannotRecognizeQRCode }

        return farmInfo
    }

    func createFile(geojson: GeoJSON<PolygonGeometry>) -> FileObject? {
        // [1]
        let fileURL = FileUtils.QRCodeFiles.temporaryFileURL
        let stringData: String = (geojson.prettyPrintedJSONString) as String
        let data = stringData.data(using: .utf8)
        let success = fileStorage.createFile(at: fileURL, content: data)
        guard success else { return nil }

        // [2]
        #if DEBUG
        let resultData: Data? = fileStorage.contents(of: fileURL)
        if let resultData, let string: String = .init(data: resultData, encoding: .utf8) {
            log.debug("stringData: \n\(string)")
        }
        #endif

        // [3]
        let result: Result = fileStorage.contents(of: fileURL)
        switch result {
            case .success(let files):
                log.debug("files: \(files)")
                log.debug("mimeTypes: \(files.map({ $0.mimeType }))")

                return files.first
            case .failure(let error):
                log.debug("error: \(error)")

                return nil
        }
    }
}

// MARK: - Private Methods
private extension QRCodeDataServiceImpl {
    func _getFarmInfo(utmRawString: String) -> Result<FarmInfo, Swift.Error> {
        log.debug("Try to parse utm coordinates from raw string")
        do {
            let point = try utmDataGeometryParser.parsePoint(utmRawString)
            let polygonCoordinates = try utmDataGeometryParser.parsePolygon(utmRawString)
            let geojson = createGeoJson(polygonCoordinates: polygonCoordinates)
            let farmInfo: FarmInfo = .init(locationPoint: point, geojson: geojson)
            return .success(farmInfo)
        } catch let error as UTMDataGeometryParser.Error {
            switch error {
                case .cannotRecognize:
                    return .failure(Error.cannotRecognizeQRCode)
            }
        } catch {
            return .failure(error)
        }
    }

    func _getFarmInfo(latLonRawString: String) -> Result<FarmInfo, Swift.Error> {
        log.debug("Try to parse lat lon coordinates from raw string")
        do {
            let point = try latLonGeometryParser.parsePoint(latLonRawString)
            let polygonCoordinates = try latLonGeometryParser.parsePolygon(latLonRawString)
            let geojson = createGeoJson(polygonCoordinates: polygonCoordinates)
            let farmInfo: FarmInfo = .init(locationPoint: point, geojson: geojson)
            return .success(farmInfo)
        } catch let error as LatLonDataGeometryParser.Error {
            switch error {
                case .cannotRecognize:
                    return .failure(Error.cannotRecognizeQRCode)
            }
        } catch {
            return .failure(error)
        }
    }

    func createGeoJson(polygonCoordinates: [CLLocationCoordinate2D]) -> GeoJSON<PolygonGeometry> {
        let featureCoordinates: [GeoJSONPosition] = polygonCoordinates.map { .init(from: $0) }
        let featureProperties: GeoJSON<PolygonGeometry>.Feature<PolygonGeometry>.Properties = .empty()
        let geoJsonModel: GeoJSON<PolygonGeometry> = .init(
            type: .featureCollection,
            features: [
                .init(
                    geometry: .init(coordinates: [featureCoordinates]),
                    properties: featureProperties
                )
            ]
        )
        log.debug("geoJsonModel: \(geoJsonModel.prettyPrintedJSONString)")

        return geoJsonModel
    }
}
