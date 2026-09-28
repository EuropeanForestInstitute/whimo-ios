//
//  PreviewDevicesKeys.swift
//  Utility
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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

#if !RELEASE
// swiftlint:disable all
public enum PreviewDevicesKeys: String, Hashable {
    // MARK: - iPhones Old
    case iPhone7 = "iPhone 7"
    case iPhone7Plus = "iPhone 7 Plus"
    case iPhone8 = "iPhone 8"
    case iPhone8Plus = "iPhone 8 Plus"

    // MARK: - iPhones SE
    case iPhoneSE = "iPhone SE (3rd generation)"

    // MARK: - iPhone X and earlier
    case iPhoneX = "iPhone X"

    case iPhoneXs = "iPhone Xs"
    case iPhoneXsMax = "iPhone Xs Max"
    case iPhoneXR = "iPhone Xʀ"

    case iPhone11ProMax = "iPhone 11 Pro Max"

    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"

    case iPhone16 = "iPhone 16"
    case iPhone16Plus = "iPhone 16 Plus"
    case iPhone16Pro = "iPhone 16 Pro"
    case iPhone16ProMax = "iPhone 16 Pro Max"

    // MARK: - iPads
    case iPadMini4 = "iPad mini 4"
    case iPadAir2 = "iPad Air 2"
    case iPadPro_9_7 = "iPad Pro (9.7-inch)"
    case iPadPro_12_9 = "iPad Pro (12.9-inch)"
    case iPad5 = "iPad (5th generation)"
    case iPadPro_12_9_2G = "iPad Pro (12.9-inch) (2nd generation)"
    case iPadPro_10_5 = "iPad Pro (10.5-inch)"
    case iPad6 = "iPad (6th generation)"
    case iPadPro_11 = "iPad Pro (11-inch)"
    case iPadPro_12_9_3G = "iPad Pro (12.9-inch) (3rd generation)"
    case iPadPro_12_9_6G = "iPad Pro (12.9-inch) (6th generation)"
    case iPadMini5 = "iPad mini (5th generation)"
    case iPadAir_3G = "iPad Air (3rd generation)"

    // MARK: - Apple TV
    case AppleTV = "Apple TV"
    case AppleTV_4K = "Apple TV 4K"
    case AppleTV_4K1080P = "Apple TV 4K (at 1080p)"

    // MARK: - Apple Watch
    case AppleWatch2_38 = "Apple Watch Series 2 - 38mm"
    case AppleWatch2_42 = "Apple Watch Series 2 - 42mm"
    case AppleWatch3_38 = "Apple Watch Series 3 - 38mm"
    case AppleWatch3_42 = "Apple Watch Series 3 - 42mm"
    case AppleWatch4_40 = "Apple Watch Series 4 - 40mm"
    case AppleWatch4_44 = "Apple Watch Series 4 - 44mm"

    // MARK: - Macs
    case mac = "Mac"
}
// swiftlint:enable all

// MARK: - Priview device Extension
extension View {
    public func previewDevice(_ device: PreviewDevicesKeys) -> some View {
        self.previewDevice(.init(rawValue: device.rawValue))
    }
}
#endif
