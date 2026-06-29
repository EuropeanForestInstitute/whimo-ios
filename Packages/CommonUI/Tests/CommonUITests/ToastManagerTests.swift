//
//  ToastManagerTests.swift
//  CommonUI
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
import SwiftUI
@testable import CommonUI

@MainActor
final class ToastManagerTests: XCTestCase {
    private typealias ToastValue = ToastManager.ToastValue

    private var sut: ToastManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = .init()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testAddMultipleToasts() throws {
        let toast1: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "First Toast", duration: 2)
        let toast2: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Second Toast", duration: 2)

        sut.append(toast1)
        sut.append(toast2)

        XCTAssertEqual(sut.models.count, 2)
        XCTAssertEqual(sut.models[0].id, toast1.id)
        XCTAssertEqual(sut.models[1].id, toast2.id)
    }

    func testAddWithTask() async throws {
        let result = try await sut.append(
            message: "Loading...",
            task: {
                try await Task.sleep(seconds: 0.1)
                return "Success"
            },
            onSuccess: { result in
                ToastValue(icon: Image(systemName: "checkmark.circle"), message: result)
            },
            onFailure: { error in
                ToastValue(icon: Image(systemName: "xmark.circle"), message: error.localizedDescription)
            }
        )

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(sut.models.count, 1)
        XCTAssertEqual(sut.models.first?.message, "Success")
    }

    func testAddWithErrorTask() async throws {
        do {
            try await sut.append(
                message: "Loading...",
                task: {
                    try await Task.sleep(seconds: 0.1)
                    throw NSError(domain: "", code: 0)
                },
                onSuccess: { result in
                    ToastValue(icon: Image(systemName: "checkmark.circle"), message: result)
                },
                onFailure: { error in // swiftlint:disable:this unused_closure_parameter
                    ToastValue(icon: Image(systemName: "xmark.circle"), message: "Error")
                }
            )
        } catch {}
        XCTAssertEqual(sut.models.count, 1)
        XCTAssertEqual(sut.models.first?.message, "Error")
    }

    func testAddWithReplacement() throws {
        let toast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Toast", duration: 2)
        let newToast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "New Toast", duration: 2)

        sut.append(toast)
        sut.replace(old: toast, new: newToast)

        XCTAssertEqual(sut.models.count, 1)
        XCTAssertEqual(sut.models[0].id, newToast.id)
    }

    func testIsPresented() {
        XCTAssertFalse(sut.isPresented)

        let toast = ToastValue(message: "Test Message")
        sut.append(toast)

        XCTAssertTrue(sut.isPresented)
    }

    func testOnAppear() {
        XCTAssertFalse(sut.isAppeared)

        sut.onAppear()

        XCTAssertTrue(sut.isAppeared)
    }

    func testToastCustomization() throws {
        let toast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Custom Toast", duration: 3)

        sut.append(toast)

        XCTAssertEqual(toast.message, "Custom Toast")
        XCTAssertEqual(toast.duration, 3)
    }

    func testToastAutoDismissal() throws {
        let expectation = XCTestExpectation(description: "Should dismiss toast")
        let toast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Auto Dismiss", duration: 0.25)

        sut.append(toast)
        Task {
            await sut.startRemovalTask(for: toast)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(sut.models.isEmpty, "Manager must has no toasts")
        XCTAssertFalse(sut.isPresented, "Manager must be unpresented after dismiss all toasts")
    }

    func testManualDismissal() throws {
        let toast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Manual Dismiss", duration: nil)

        sut.append(toast)
        sut.remove(toast)

        XCTAssertTrue(sut.models.isEmpty, "Manager must has no toasts")
        XCTAssertFalse(sut.isPresented, "Manager must be unpresented after dismiss all toasts")
    }

    func testDismissAllToasts() throws {
        let toast1: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Toast 1", duration: nil)
        let toast2: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Toast 2", duration: nil)

        sut.append(toast1)
        sut.append(toast2)

        sut.models.forEach { sut.remove($0) }

        XCTAssertTrue(sut.models.isEmpty, "Manager must has no toasts")
        XCTAssertFalse(sut.isPresented, "Manager must be unpresented after dismiss all toasts")
    }

    func testRemoveNonExistentToast() throws {
        let toast: ToastValue = .init(icon: ToastRootView.LoadingView(), message: "Non-existent Toast", duration: nil)

        sut.remove(toast)

        XCTAssertTrue(sut.models.isEmpty, "Manager must has no toasts")
    }
}
