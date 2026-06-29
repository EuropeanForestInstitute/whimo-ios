//
//  Package.swift
//  Whimo
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
// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utility",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Utility",
            targets: ["Utility"]
        ),
    ],
    dependencies: [
        .package(path: "../Extensions"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections?tab=readme-ov-file", exact: "1.1.1"),
        .package(url: "https://github.com/hmlongco/Factory.git", exact: "2.5.3"),
        .package(url: "https://github.com/guykogus/CodableGeoJSON", exact: "4.0.0")
    ],
    targets: [
        .target(
            name: "Utility",
            dependencies: [
                "Extensions",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections?tab=readme-ov-file"),
                .product(name: "FactoryKit", package: "Factory"),
                .product(name: "CodableGeoJSON", package: "CodableGeoJSON")
            ],
        ),
        .testTarget(
            name: "UtilityTests",
            dependencies: ["Utility"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
