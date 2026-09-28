//
//  CataloguePagination.swift
//  Whimo
//
//  Created by Pavel Pushkarev on 14.09.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
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
import RestClient

/// Verifies that a catalogue snapshot contains every declared page and row before it can be saved.
struct CataloguePagination {
    private(set) var page = 1
    private var receivedCount = 0
    private var expectedCount: Int?
    private var expectedPages: Int?

    mutating func advance(_ pagination: RestClient.Pagination?, itemCount: Int) throws -> Bool {
        guard let pagination, pagination.page == page, pagination.pageSize > 0,
              pagination.count >= .zero, pagination.totalPages >= 0,
              expectedCount == nil || expectedCount == pagination.count,
              expectedPages == nil || expectedPages == pagination.totalPages else {
            throw CocoaError(.coderInvalidValue)
        }
        expectedCount = pagination.count
        expectedPages = pagination.totalPages
        receivedCount += itemCount
        guard receivedCount <= pagination.count else { throw CocoaError(.coderInvalidValue) }

        if let next = pagination.nextPage {
            guard next == page + 1, next <= pagination.totalPages, itemCount > 0 else { throw CocoaError(.coderInvalidValue) }

            page = next
            return true
        }
        guard receivedCount == pagination.count,
              page == pagination.totalPages || (page == 1 && pagination.totalPages == 0 && receivedCount == 0) else {
            throw CocoaError(.coderInvalidValue)
        }
        return false
    }
}
