//
//  GeojsonMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.07.2025.
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
import RestClient
import Utility

struct GeojsonMapper: GeojsonMapperProtocol {
    private func mapType(
        dto: ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.GeoJSONType
    ) -> GeoJSON<PolygonGeometry>.GeoJSONType {
        switch dto {
            case .featureCollection:
                return .featureCollection
        }
    }

    private func mapFeatureType(
        dto: ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature.FeatureType
    ) -> GeoJSON<PolygonGeometry>.Feature<PolygonGeometry>.FeatureType {
        switch dto {
            case .feature:
                return .feature
        }
    }

    private func mapGeometry(
        dto: ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature.PolygonGeometry
    ) -> PolygonGeometry {
        guard
            let coordinates = dto.coordinates[safe: 0]
        else { return .init(coordinates: []) }

        let linearCoordinates: PolygonGeometry.LinearRing = coordinates
            .reduce(into: [(lat: Double, lon: Double)]()) { partialResult, array in
                guard
                    let lat = array.first,
                    let lon = array.last
                else { return }

                partialResult.append((lat, lon))
            }
            .map { .init(latitude: $0.lat, longitude: $0.lon) }
        let polygon: PolygonGeometry = .init(coordinates: [linearCoordinates])
        return polygon
    }

    private func mapProperties(
        dto: ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature.Properties
    ) -> GeoJSON<PolygonGeometry>.Feature<PolygonGeometry>.Properties {
        .init(
            producerName: dto.producerName,
            producerCountry: dto.producerCountry,
            productionPlace: dto.productionPlace
        )
    }

    private func mapFeature(
        dto: ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature
    ) -> GeoJSON<PolygonGeometry>.Feature<PolygonGeometry> {
        .init(
            type: mapFeatureType(dto: dto.type),
            id: dto.id ?? .zero,
            geometry: mapGeometry(dto: dto.geometry),
            properties: mapProperties(dto: dto.properties)
        )
    }

    func toGeojson(dto: ResponseModels.DownloadGeojson) -> GeoJSON<PolygonGeometry> {
        .init(
            type: mapType(dto: dto.data.featureCollection.type),
            features: dto.data.featureCollection.features.map(mapFeature)
        )
    }
}
