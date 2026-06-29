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
import CodableGeoJSON

// MARK: - QRCodeDataServiceImpl
final class QRCodeDataServiceImpl: QRCodeDataService {
    // MARK: - Dependencies
    private let fileStorage: any FileStorageServiceProtocol

    private let decoder: JSONDecoder = .init()

    // MARK: - Init
    init(fileStorage: any FileStorageServiceProtocol) {
        self.fileStorage = fileStorage
    }

    // MARK: - QRCodeDataService
    func saveGroundFarmInfo(from rawString: String) throws -> (coordinates: CLLocationCoordinate2D, selectedFile: FileObject?) {
        let geojson = try parseGeojsonFarmInfo(from: rawString)
        log.debug("parsed geojson: \(geojson)")

        let farmCoordinates = try parseFarmLocation(from: geojson)
        let geojsonData = (geojson.prettyPrintedJSONString as String).data(using: .utf8)
        let file = createFile(data: geojsonData)

        return (coordinates: farmCoordinates, selectedFile: file)
    }
}

// MARK: - Private Methods
private extension QRCodeDataServiceImpl {
    func parseGeojsonFarmInfo(from rawString: String) throws -> GeoJSON {
        let data: Data = rawString.data(using: .utf8) ?? .init()

        do {
            return try decoder.decode(GeoJSON.self, from: data)
        } catch {
            log.error("Cannot parse geojson raw data: \(error.localizedDescription)")
            throw Error.cannotRecognizeQRCode
        }
    }

    func parseFarmLocation(from geojson: GeoJSON) throws -> CLLocationCoordinate2D {
        func handleGeometry(_ geometry: GeoJSON.Geometry?) -> CLLocationCoordinate2D? {
            guard let geometry = geometry else { return nil }

            switch geometry {
                case .point(let coordinates):
                    return .init(from: coordinates)
                case .multiPoint(let coordinates):
                    return nil
                case .lineString(let coordinates):
                    return nil
                case .multiLineString(let coordinates):
                    return nil
                case .polygon(let coordinates):
                    guard let coordinates = coordinates.first?.first else { return nil }

                    return .init(from: coordinates)
                case .multiPolygon(let coordinates):
                    return nil
                case .geometryCollection(let geometries):
                    return nil
            }
        }

        let coordinate: CLLocationCoordinate2D?
        switch geojson {
            case .feature(let feature, let boundingBox):
                coordinate = handleGeometry(feature.geometry)
            case .featureCollection(let featureCollection, let boundingBox):
                coordinate = nil
            case .geometry(let geometry, let boundingBox):
                coordinate = handleGeometry(geometry)
        }

        guard let coordinate else {
            throw Error.unsupportedQRCode
        }

        return coordinate
    }

    func createFile(data: Data?) -> FileObject? {
        // [1]
        let fileURL = FileUtils.QRCodeFiles.temporaryFileURL
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
                log.error("Cannot create file: \(error.localizedDescription)")

                return nil
        }
    }
}
