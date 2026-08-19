//
//  CLLocationCoordinate2D+GeoJSONPosition.swift
//  Utility
//
//  Created by Vyacheslav Razumeenko on 03.06.2026.
//

import Foundation
import CoreLocation
import CodableGeoJSON

extension CLLocationCoordinate2D {
    public init(from position: GeoJSONPosition) {
        self.init(latitude: position.latitude, longitude: position.longitude)
    }
}
