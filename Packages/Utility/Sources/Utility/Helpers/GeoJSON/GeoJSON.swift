//
//  GeoJSON.swift
//  Utility
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
import struct CoreLocation.CLLocationCoordinate2D

// MARK: - GeoJSON
public struct GeoJSON<Geometry>: Codable, Sendable, AutoStringConvertible where Geometry: GeoJSONGeometry {
    // MARK: - GeoJSONType
    public enum GeoJSONType: String, Codable, Sendable {
        case featureCollection = "FeatureCollection"
    }

    // MARK: - Properties
    public let `type`: GeoJSONType
    /// The features of the collection.
    public let features: [Feature<Geometry>]

    public init(`type`: GeoJSONType, features: [Feature<Geometry>]) {
        self.`type` = `type`
        self.features = features
    }
}

// MARK: - Feature
extension GeoJSON {
    public struct Feature<GeometryObj>: Codable, Sendable, AutoStringConvertible where GeometryObj: GeoJSONGeometry {
        // MARK: - FeatureType
        public enum FeatureType: String, Codable, Sendable {
            case feature = "Feature"
        }

        public let type: FeatureType
        /// A commonly used identifier, if known.
        /// https://datatracker.ietf.org/doc/html/rfc7946#section-3.2
        public let id: Int?
        public let geometry: Geometry
        public let properties: Properties

        public init(type: FeatureType = .feature, id: Int? = nil, geometry: Geometry, properties: Properties) {
            self.type = type
            self.id = id
            self.geometry = geometry
            self.properties = properties
        }
    }
}

// MARK: - Properties
extension GeoJSON.Feature {
    public struct Properties: Codable, Sendable, AutoStringConvertible {
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

        public static func empty() -> Self {
            .init(producerName: nil, producerCountry: nil, productionPlace: nil)
        }
    }
}

// https://github.com/guykogus/CodableGeoJSON/blob/main/CodableGeoJSON/GeoJSONGeometry.swift

/// A region of space.
public protocol GeoJSONGeometry: Codable, Hashable, Sendable {}

// MARK: - PolygonGeometry
/// An array of linear rings.
public struct PolygonGeometry: GeoJSONGeometry, AutoStringConvertible {
    /// A closed "Line String" with four or more positions.
    public typealias LinearRing = [GeoJSONPosition]
    public typealias Coordinates = [LinearRing]

    public let coordinates: Coordinates
    public let type: String

    public init(coordinates: Coordinates) {
        self.coordinates = coordinates
        self.type = "Polygon"
    }

    /// The first `LinearRing` of a polygon represents its external ring.
    public var exteriorRing: Coordinates.Element? {
        coordinates.first
    }

    /// The internal holes of the polygon. May be empty.
    public var internalRings: Coordinates.SubSequence {
        coordinates.dropFirst()
    }
}

// https://github.com/guykogus/CodableGeoJSON/blob/main/CodableGeoJSON/GeoJSONPosition.swift

/// The fundamental geometry construct.
public struct GeoJSONPosition: Hashable, Sendable, AutoStringConvertible {
    /// The latitudinal coordinate.
    public let latitude: Double
    /// The longitudinal coordinate.
    public let longitude: Double
    /// The elevation at the coordinates.
    public let elevation: Double?

    /// Create a new `GeoJSONPosition`
    ///
    /// - Parameters:
    ///   - longitude: The longitudinal coordinate.
    ///   - latitude: The latitudinal coordinate.
    ///   - elevation: The elevation at the coordinates.
    public init(latitude: Double, longitude: Double, elevation: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}

// MARK: - Codable

extension GeoJSONPosition: Codable {
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        longitude = try container.decode(Double.self)
        latitude = try container.decode(Double.self)
        elevation = try container.decodeIfPresent(Double.self)
    }

    public init(from coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
        if let elevation {
            try container.encode(elevation)
        }
    }
}
