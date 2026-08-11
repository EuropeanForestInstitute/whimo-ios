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
    name: "Persistence",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "DatabaseKit",
            targets: ["DatabaseKit"]
        ),
        .library(
            name: "StorageKit",
            targets: ["StorageKit"]
        )
    ],
    dependencies: [
        .package(path: "../Utility"),
        .package(path: "../Extensions"),
        .package(url: "https://github.com/groue/GRDB.swift", exact: "7.6.1"),
        .package(url: "https://github.com/auth0/SimpleKeychain.git", exact: "1.3.0")
    ],
    targets: [
        .target(
            name: "DatabaseKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SimpleKeychain", package: "SimpleKeychain"),
                "Extensions",
                "Utility"
            ]
        ),
        .target(
            name: "StorageKit",
            dependencies: [
                "Utility",
                .product(name: "SimpleKeychain", package: "SimpleKeychain")
            ]
        ),
        .testTarget(
            name: "DatabaseTests",
            dependencies: ["DatabaseKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
