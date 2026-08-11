//
//  TransactionModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 04.06.2025.
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
import Utility

// MARK: - TransactionModel
struct TransactionModel: DomainModel, AutoStringConvertible {
    let id: String
    let createdAt: String
    let expiresAt: String?
    let updatedAt: String?
    let type: TransactionType
    let status: Status
    let action: Action
    let traceability: Traceability?
    let location: LocationType?
    let farmLatitude: Double?
    let farmLongitude: Double?
    let transactionLatitude: Double?
    let transactionLongitude: Double?
    let volume: Double
    let isBuyingFromFarmer: Bool
    let commodity: CommodityGroupModel.Commodity
    let seller: UserModel?
    let buyer: UserModel?
    let createdById: String?

    var persistingData: PersistingData
}

// MARK: - Transaction
extension TransactionModel {
    enum TransactionType: String, DomainModel {
        case producer
        case downstream
        case conversion

        var id: Self { self }
    }
}

// MARK: - Status
extension TransactionModel {
    enum Status: String, DomainModel {
        case accepted
        case rejected
        case pending
        case noResponse
        case recorded
        case automatic

        var id: Self { self }

        var goodStatus: Bool {
            switch self {
                case .accepted:
                    true
                case .rejected, .pending, .automatic, .noResponse, .recorded:
                    false
            }
        }
    }
}

// MARK: - Action
extension TransactionModel {
    enum Action: String, DomainModel {
        case buy = "buying"
        case sell = "selling"

        var id: Self { self }
    }
}

extension TransactionModel {
    enum Traceability: String, DomainModel {
        case fullTraceability
        case conditionalTraceability
        case partialTraceability
        case incompleteTraceability

        var id: Self { self }
        var isMissingLocation: Bool {
            switch self {
                case .fullTraceability, .conditionalTraceability:
                    false
                case .partialTraceability, .incompleteTraceability:
                    true
            }
        }
    }
}

// MARK: - LocationType
extension TransactionModel {
    enum LocationType: String, DomainModel {
        case qrCode = "qr"
        case manual = "manual"
        case file = "file"
        case gps = "gps"

        var id: Self { self }
    }
}

// MARK: - PersistingData
extension TransactionModel {
    struct PersistingData: DomainModel {
        let farmLocationFile: File?
        let state: State

        var id: Self { self }

        private init(farmLocationFile: File?, state: State) {
            self.farmLocationFile = farmLocationFile
            self.state = state
        }

        static func onDisk(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .onDisk)
        }

        static func sync(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .sync)
        }

        static func error(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .error)
        }

        static func uploading(farmLocationFile: File? = nil) -> Self {
            .init(farmLocationFile: farmLocationFile, state: .uploading)
        }

        // MARK: - State
        enum State: DomainModel {
            case onDisk
            case sync
            case error
            case uploading

            var id: Self { self }
            var isPersistable: Bool {
                switch self {
                    case .onDisk, .sync, .error:
                        true
                    case .uploading:
                        false
                }
            }
            var isUploading: Bool {
                switch self {
                    case .onDisk, .sync, .error:
                        false
                    case .uploading:
                        true
                }
            }
        }
    }
}

// MARK: - File
extension TransactionModel.PersistingData {
    struct File: DomainModel {
        let fileURL: URL
        let fileName: String
        let mimeType: String

        var id: Self { self }

        init(fileURL: URL, fileName: String, mimeType: String) {
            self.fileURL = fileURL
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}
