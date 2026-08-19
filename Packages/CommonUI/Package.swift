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
    name: "CommonUI",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "CommonUI",
            targets: ["CommonUI"]
        ),
    ],
    dependencies: [
        .package(path: "../Utility"),
        .package(path: "../Resources"),
        .package(path: "../Extensions"),
        .package(url: "https://github.com/sunghyun-k/swiftui-window-overlay", exact: "1.0.2"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit", exact: "4.1.3")
    ],
    targets: [
        .target(
            name: "CommonUI",
            dependencies: [
                "Utility",
                "Resources",
                "Extensions",
                .product(name: "WindowOverlay", package: "swiftui-window-overlay"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit")
            ]
        ),
        .testTarget(
            name: "CommonUITests",
            dependencies: [
                "CommonUI",
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
