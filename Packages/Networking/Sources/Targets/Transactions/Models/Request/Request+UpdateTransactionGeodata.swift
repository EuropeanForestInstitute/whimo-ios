//
//  Request+UpdateTransactionGeodata.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 14.06.2025.
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
import Networking
import RestClient

extension RequestModels {
    public struct UpdateTransactionGeodata: Encodable {
        public let transactionId: String
        public let transactionData: TransactionData
        public let uploadFile: UploadFile

        public init(transactionId: String, transactionData: TransactionData, uploadFile: UploadFile) {
            self.transactionId = transactionId
            self.transactionData = transactionData
            self.uploadFile = uploadFile
        }
    }
}

// MARK: - TransactionData
extension RequestModels.UpdateTransactionGeodata {
    public struct TransactionData: DataMultipartEncodable {
        public let location: LocationType

        public init(location: LocationType) {
            self.location = location
        }
    }
}

// MARK: - UploadFile
extension RequestModels.UpdateTransactionGeodata {
    public struct UploadFile: FileMultipartEncodable {
        public let fileURL: URL
        public let name: String
        public let fileName: String
        public let mimeType: String

        public init(fileURL: URL, fileName: String, mimeType: String) {
            self.fileURL = fileURL
            self.name = "location_file"
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}

// MARK: - LocationType
extension RequestModels.UpdateTransactionGeodata.TransactionData {
    public enum LocationType: String, Encodable {
        case qrCode = "qr"
        case manual = "manual"
        case file = "file"
        case gps = "gps"
    }
}
