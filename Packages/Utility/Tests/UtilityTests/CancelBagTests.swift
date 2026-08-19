//
//  CancelBagTests.swift
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

import XCTest
import Combine
@testable import Utility

final class CancelBagTests: XCTestCase {
    private var sut: CancelBag!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = .init()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testStoreSingle() throws {
        let cancellable: AnyCancellable = .init { }

        sut.store(cancellable)

        XCTAssertEqual(sut.subscriptions.count, 1, "CancelBag should store one subscription")
    }

    func testStoreSingleAnyCancellableExtension() throws {
        let cancellable: AnyCancellable = .init { }

        cancellable.store(in: sut)

        XCTAssertEqual(sut.subscriptions.count, 1, "CancelBag should store one subscription")
    }

    func testStoreMultiple() throws {
        let cancellable1: AnyCancellable = .init { }
        let cancellable2: AnyCancellable = .init { }
        let cancellable3: AnyCancellable = .init { }

        sut.store(cancellable1)
        sut.store(cancellable2)
        sut.store(cancellable3)

        XCTAssertEqual(sut.subscriptions.count, 3, "CancelBag should store three subscriptions")
    }

    func testStoreCancel() throws {
        var wasCalled = false
        let cancellable1: AnyCancellable = .init { wasCalled = true }
        let cancellable2: AnyCancellable = .init { }
        let cancellable3: AnyCancellable = .init { }

        sut.store(cancellable1)
        sut.store(cancellable2)
        sut.store(cancellable3)

        sut.cancel()
        XCTAssertTrue(wasCalled, "Cancellation should trigger cancellable closure")
        XCTAssertEqual(sut.subscriptions.count, 0, "CancelBag should be empty after cancel")
    }
}
