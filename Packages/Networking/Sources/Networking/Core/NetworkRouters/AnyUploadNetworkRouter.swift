//
//  AnyUploadNetworkRouter.swift
//  Networking
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

import Foundation
import Alamofire

// MARK: - AnyUploadNetworkRouter
public protocol AnyUploadNetworkRouter {
    typealias Endpoint = String

    var uploadData: [MultipartUpload] { get }
    var path: Endpoint { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var addAuth: Bool { get }

    var overridenEncoder: JSONEncoder? { get }
    var overridenDecoder: JSONDecoder? { get }
}

public extension AnyUploadNetworkRouter {
    var method: HTTPMethod { .post }
    var headers: HTTPHeaders? {
        [
            HTTPHeader.accept("application/json"),
            HTTPHeader.contentType("multipart/form-data")
        ]
    }
    var addAuth: Bool { false }

    var overridenEncoder: JSONEncoder? { nil }
    var overridenDecoder: JSONDecoder? { nil }
}

// MARK: - FileMultipartEncodable
public protocol FileMultipartEncodable: Encodable {
    var fileURL: URL { get }
    var name: String { get }
    var fileName: String { get }
    var fileType: String { get }
    var mimeType: String { get }
}

public extension FileMultipartEncodable {
    var fileName: String { "" }
    var fileType: String { "" }
    var mimeType: String { "" }
}

// MARK: - DataMultipartEncodable
public protocol DataMultipartEncodable: Encodable { }

// MARK: - MultipartUpload
public enum MultipartUpload {
    case file(FileMultipartEncodable)
    case data(DataMultipartEncodable)
}
