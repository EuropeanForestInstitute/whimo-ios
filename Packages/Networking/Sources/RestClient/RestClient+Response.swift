//
//  RestClient+Response.swift
//  Networking
//
//  Created by Vyacheslav Razumeenko on 15.07.2025.
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

// MARK: - Request

// MARK: - PaginationEncodable
public protocol PaginationEncodable: Encodable {
    var page: Int { get }
    var pageSize: Int { get }
}

// MARK: - PaginationRequest
public struct PaginationRequest: PaginationEncodable, Equatable {
    public let page: Int
    public let pageSize: Int

    public static let initial: PaginationRequest = .init(
        page: 1,
        pageSize: 20
    )

    public static let single: PaginationRequest = .init(
        page: 1,
        pageSize: 1
    )

    public static let full: PaginationRequest = .init(
        page: 1,
        pageSize: .max
    )

    public init(page: Int, pageSize: Int) {
        self.page = page
        self.pageSize = pageSize
    }
}

// MARK: - Response

// MARK: - AnyResponse
public protocol AnyResponse: Decodable { }

// MARK: - AnyDataResponse
public protocol AnyDataResponse: AnyResponse {
    associatedtype T: Decodable

    var data: T { get }
}

// MARK: - AnyPaginationDataResponse
public protocol AnyPaginationDataResponse: AnyResponse {
    typealias Pagination = RestClient.Pagination

    var pagination: Pagination { get }
}

// MARK: - VoidResponse
public struct VoidResponse: AnyResponse { }
