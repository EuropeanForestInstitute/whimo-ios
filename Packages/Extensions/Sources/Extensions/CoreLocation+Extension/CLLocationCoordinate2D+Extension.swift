//
//  CLLocationCoordinate2D+Extension.swift
//  Extensions
//
//  Created by Vyacheslav Razumeenko on 21.05.2025.
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

import CoreLocation

extension CLLocationCoordinate2D {
    /// Returns a string in the format "DD°MM'SS.S\"H", where H is N/S/E/W
    public func formatToDMS() -> String {
        func toDMS(degrees: CLLocationDegrees, isLatitude: Bool) -> String {
            let absolute = abs(degrees)
            let degrees = Int(absolute)
            let minutesFull = (absolute - Double(degrees)) * 60
            let minutes = Int(minutesFull)
            let seconds = (minutesFull - Double(minutes)) * 60

            let secondsFormatted = String(format: "%.1f", seconds)

            let hemisphere: String
            if isLatitude {
                hemisphere = degrees >= 0 ? "N" : "S"
            } else {
                hemisphere = degrees >= 0 ? "E" : "W"
            }

            return "\(degrees)°\(minutes)'\(secondsFormatted)\"\(hemisphere)"
        }

        let latitude = toDMS(degrees: self.latitude, isLatitude: true)
        let longitude = toDMS(degrees: self.longitude, isLatitude: false)
        let dms = "\(latitude) \(longitude)"
        return dms
    }
}
