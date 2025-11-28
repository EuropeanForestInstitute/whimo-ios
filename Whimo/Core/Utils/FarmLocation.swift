//
//  FarmLocation.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.05.2025.
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

enum FarmLocation: Equatable {
    case qrCode(file: FileObject, coordinates: CLLocationCoordinate2D)
    case fileManager(file: FileObject, coordinates: CLLocationCoordinate2D)
    case gps(coordinates: CLLocationCoordinate2D)
    case manual(coordinates: CLLocationCoordinate2D)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case let (.qrCode(lFile, lCoordinates), .qrCode(rFile, rCoordinates)):
                lFile == rFile && lCoordinates == rCoordinates
            case let (.fileManager(lFile, lCoordinates), .fileManager(rFile, rCoordinates)):
                lFile == rFile && lCoordinates == rCoordinates
            case let (.gps(lCoordinates), .gps(rCoordinates)):
                lCoordinates == rCoordinates
            case let (.manual(lCoordinates), .manual(rCoordinates)):
                lCoordinates == rCoordinates
            default:
                false
        }
    }

    var coordinates: CLLocationCoordinate2D {
        switch self {
            case
                    .qrCode(_, let coordinates),
                    .fileManager(_, let coordinates),
                    .gps(let coordinates),
                    .manual(let coordinates):
                coordinates
        }
    }

    var selectedFile: FileObject? {
        switch self {
            case .qrCode(let file, _):
                file
            case .fileManager(let file, _):
                file
            default:
                nil
        }
    }
}
