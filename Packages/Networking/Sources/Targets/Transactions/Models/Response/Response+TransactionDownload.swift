//
//  Response+TransactionDownload.swift
//  Whimo
//
//  Created by AI on 2024-07-06.
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

extension ResponseModels {
    public struct DownloadGeojson: AnyDataResponse {
        public let data: FeatureCollection

        public init(data: FeatureCollection) {
            self.data = data
        }

        public struct FeatureCollection: Decodable {
            public let featureCollection: GeoJSON

            public init(featureCollection: GeoJSON) {
                self.featureCollection = featureCollection
            }
        }
    }
}

extension ResponseModels.DownloadGeojson.FeatureCollection {
    // MARK: - GeoJSON
    public struct GeoJSON: Decodable {
        // MARK: - GeoJSONType
        public enum GeoJSONType: String, Codable, Sendable {
            case featureCollection = "FeatureCollection"
        }

        // MARK: - Properties
        public let `type`: GeoJSONType
        /// The features of the collection.
        public let features: [Feature]

        public init(`type`: GeoJSONType, features: [Feature]) {
            self.`type` = `type`
            self.features = features
        }
    }
}

// MARK: - Feature
extension ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON {
    public struct Feature: Decodable {
        // MARK: - FeatureType
        public enum FeatureType: String, Codable, Sendable {
            case feature = "Feature"
        }

        public let type: FeatureType
        public let id: Int?
        public let geometry: PolygonGeometry
        public let properties: Properties

        public init(type: FeatureType, id: Int?, geometry: PolygonGeometry, properties: Properties) {
            self.type = type
            self.id = id
            self.geometry = geometry
            self.properties = properties
        }
    }
}

// MARK: - Properties
extension ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature {
    public struct Properties: Decodable {
        public let producerName: String?
        public let producerCountry: String?
        public let productionPlace: String?

        public enum CodingKeys: String, CodingKey {
            case producerName = "ProducerName"
            case producerCountry = "ProducerCountry"
            case productionPlace = "ProductionPlace"
        }

        public init(producerName: String?, producerCountry: String?, productionPlace: String?) {
            self.producerName = producerName
            self.producerCountry = producerCountry
            self.productionPlace = productionPlace
        }
    }
}

// MARK: - PolygonGeometry
extension ResponseModels.DownloadGeojson.FeatureCollection.GeoJSON.Feature {
    /// An array of linear rings.
    public struct PolygonGeometry: Decodable {
        public let coordinates: [[[Double]]]
        public let type: String

        public init(coordinates: [[[Double]]]) {
            self.coordinates = coordinates
            self.type = "Polygon"
        }
    }

}
