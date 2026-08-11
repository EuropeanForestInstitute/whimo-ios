//
//  ChooseFarmGeodata+Row.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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

import SwiftUI
import typealias Utility.DomainModel
import Resources

private typealias Module = ChooseFarmGeodataModule
private typealias Localization = AppLocale.ChooseFarmGeodata.Row
private typealias Assets = AppAssets.ChooseFarmGeodata

// MARK: - Row
extension Module {
    enum Row: DomainModel, CaseIterable {
        case qrCode
        case currentLocation
        case uploadFile
        case addLocation

        var id: Self { self }

        var title: String {
            switch self {
                case .qrCode:
                    Localization.Qr.title
                case .currentLocation:
                    Localization.CurrentLocation.title
                case .uploadFile:
                    Localization.UploadFile.title
                case .addLocation:
                    Localization.AddLocation.title
            }
        }

        var subtitle: String {
            switch self {
                case .qrCode:
                    Localization.Qr.subtitle
                case .currentLocation:
                    Localization.CurrentLocation.subtitle
                case .uploadFile:
                    Localization.UploadFile.subtitle
                case .addLocation:
                    Localization.AddLocation.subtitle
            }
        }

        var image: Image {
            switch self {
                case .qrCode:
                    Assets.chooseFarmGeoQrIcon.imageSwiftUI
                case .currentLocation:
                    Assets.chooseFarmGeoMapPin.imageSwiftUI
                case .uploadFile:
                    Assets.chooseFarmGeoUpload.imageSwiftUI
                case .addLocation:
                    Assets.chooseFarmGeoMap.imageSwiftUI
            }
        }
    }
}
