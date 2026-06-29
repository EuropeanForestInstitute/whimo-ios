//
//  NonEmptyArrayTests.swift
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
import XCTest
@testable import Utility

final class NonEmptyArrayTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithFirstAndRest() async throws {
        // Given
        let first = "first"
        let rest = ["second", "third"]

        // When
        let nonEmptyArray = NonEmptyArray(first, rest)

        // Then
        XCTAssertEqual(nonEmptyArray.first, "first")
        XCTAssertEqual(nonEmptyArray.elements, ["first", "second", "third"])
        XCTAssertEqual(nonEmptyArray.count, 3)
    }

    func testInitWithFirstOnly() async throws {
        // Given
        let first = "single"

        // When
        let nonEmptyArray = NonEmptyArray(first)

        // Then
        XCTAssertEqual(nonEmptyArray.first, "single")
        XCTAssertEqual(nonEmptyArray.elements, ["single"])
        XCTAssertEqual(nonEmptyArray.count, 1)
        XCTAssertTrue(nonEmptyArray.isSingle)
    }

    func testInitFromArraySuccess() async throws {
        // Given
        let array = ["first", "second", "third"]

        // When
        let nonEmptyArray = NonEmptyArray(array)

        // Then
        XCTAssertNotNil(nonEmptyArray)
        XCTAssertEqual(nonEmptyArray?.elements, array)
        XCTAssertEqual(nonEmptyArray?.count, 3)
    }

    func testInitFromEmptyArrayReturnsNil() async throws {
        // Given
        let emptyArray: [String] = []

        // When
        let nonEmptyArray = NonEmptyArray(emptyArray)

        // Then
        XCTAssertNil(nonEmptyArray)
    }

    // MARK: - Property Tests

    func testFirstProperty() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray.first, "first")
    }

    func testLastProperty() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray.last, "third")
    }

    func testLastPropertyWithSingleElement() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("single")

        // When & Then
        XCTAssertEqual(nonEmptyArray.last, "single")
    }

    func testElementsProperty() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray.elements, ["first", "second", "third"])
    }

    func testCountProperty() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray.count, 3)
    }

    func testIsSingleProperty() async throws {
        // Given
        let singleArray = NonEmptyArray("single")
        let multiArray = NonEmptyArray("first", ["second"])

        // When & Then
        XCTAssertTrue(singleArray.isSingle)
        XCTAssertFalse(multiArray.isSingle)
    }

    // MARK: - Subscript Tests

    func testSubscriptAccess() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray[0], "first")
        XCTAssertEqual(nonEmptyArray[1], "second")
        XCTAssertEqual(nonEmptyArray[2], "third")
    }

    // MARK: - Map Tests

    func testMapTransformation() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray(1, [2, 3])

        // When
        let mapped = nonEmptyArray.map { $0 * 2 }

        // Then
        XCTAssertEqual(mapped.elements, [2, 4, 6])
    }

    func testMapWithDifferentType() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray(1, [2, 3])

        // When
        let mapped = nonEmptyArray.map { "\($0)" }

        // Then
        XCTAssertEqual(mapped.elements, ["1", "2", "3"])
    }

    // MARK: - Filter Tests

    func testFilterWithResults() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray(1, [2, 3, 4, 5])

        // When
        let filtered = nonEmptyArray.filter { $0 % 2 == 0 }

        // Then
        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered?.elements, [2, 4])
    }

    func testFilterWithNoResults() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray(1, [3, 5])

        // When
        let filtered = nonEmptyArray.filter { $0 % 2 == 0 }

        // Then
        XCTAssertNil(filtered)
    }

    func testFilterWithAllResults() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray(2, [4, 6])

        // When
        let filtered = nonEmptyArray.filter { $0 % 2 == 0 }

        // Then
        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered?.elements, [2, 4, 6])
    }

    // MARK: - Append Tests

    func testAppendingElement() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second"])

        // When
        let appended = nonEmptyArray.appending("third")

        // Then
        XCTAssertEqual(appended.elements, ["first", "second", "third"])
        XCTAssertEqual(appended.count, 3)
    }

    func testAppendingToSingleElement() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first")

        // When
        let appended = nonEmptyArray.appending("second")

        // Then
        XCTAssertEqual(appended.elements, ["first", "second"])
        XCTAssertEqual(appended.count, 2)
    }

    // MARK: - Prepend Tests

    func testPrependingElement() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("second", ["third"])

        // When
        let prepended = nonEmptyArray.prepending("first")

        // Then
        XCTAssertEqual(prepended.elements, ["first", "second", "third"])
        XCTAssertEqual(prepended.count, 3)
    }

    func testPrependingToSingleElement() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("second")

        // When
        let prepended = nonEmptyArray.prepending("first")

        // Then
        XCTAssertEqual(prepended.elements, ["first", "second"])
        XCTAssertEqual(prepended.count, 2)
    }

    // MARK: - Collection Tests

    func testCollectionConformance() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When & Then
        XCTAssertEqual(nonEmptyArray.startIndex, 0)
        XCTAssertEqual(nonEmptyArray.endIndex, 3)
        XCTAssertEqual(nonEmptyArray.index(after: 0), 1)
        XCTAssertEqual(nonEmptyArray.index(after: 1), 2)
    }

    func testForEachIteration() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])
        var collected: [String] = []

        // When
        for element in nonEmptyArray {
            collected.append(element)
        }

        // Then
        XCTAssertEqual(collected, ["first", "second", "third"])
    }

    // MARK: - Equatable Tests

    func testEquatableConformance() async throws {
        // Given
        let array1 = NonEmptyArray("first", ["second"])
        let array2 = NonEmptyArray("first", ["second"])
        let array3 = NonEmptyArray("different", ["second"])

        // When & Then
        XCTAssertEqual(array1, array2)
        XCTAssertNotEqual(array1, array3)
    }

    // MARK: - Hashable Tests

    func testHashableConformance() async throws {
        // Given
        let array1 = NonEmptyArray("first", ["second"])
        let array2 = NonEmptyArray("first", ["second"])
        let array3 = NonEmptyArray("different", ["second"])

        // When & Then
        XCTAssertEqual(array1.hashValue, array2.hashValue)
        XCTAssertNotEqual(array1.hashValue, array3.hashValue)
    }

    // MARK: - CustomStringConvertible Tests

    func testCustomStringConvertible() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second", "third"])

        // When
        let description = nonEmptyArray.description

        // Then
        XCTAssertTrue(description.contains("NonEmptyArray"))
        XCTAssertTrue(description.contains("first"))
        XCTAssertTrue(description.contains("second"))
        XCTAssertTrue(description.contains("third"))
    }

    func testCustomDebugStringConvertible() async throws {
        // Given
        let nonEmptyArray = NonEmptyArray("first", ["second"])

        // When
        let debugDescription = nonEmptyArray.debugDescription

        // Then
        XCTAssertTrue(debugDescription.contains("NonEmptyArray<String>"))
        XCTAssertTrue(debugDescription.contains("first"))
        XCTAssertTrue(debugDescription.contains("second"))
    }
}
