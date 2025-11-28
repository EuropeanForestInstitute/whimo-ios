//
//  NonEmptyArray.swift
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
import Foundation

/// A wrapper that guarantees a non-empty array.
/// This type ensures that the array always contains at least one element.
public struct NonEmptyArray<Element> {
    private let _first: Element
    private let _rest: [Element]

    /// Creates a non-empty array with a first element and optional rest elements.
    /// - Parameters:
    ///   - first: The first element (guaranteed to exist)
    ///   - rest: Additional elements (can be empty)
    public init(_ first: Element, _ rest: [Element] = []) {
        self._first = first
        self._rest = rest
    }

    /// Creates a non-empty array from an existing array.
    /// - Parameter elements: The array to wrap (must not be empty)
    /// - Returns: `nil` if the array is empty
    public init?(_ elements: [Element]) {
        guard !elements.isEmpty else { return nil }

        self._first = elements[0]
        self._rest = Array(elements.dropFirst())
    }

    /// The first element of the array (guaranteed to exist).
    public var first: Element { _first }

    /// The last element of the array.
    public var last: Element {
        _rest.isEmpty ? _first : _rest[_rest.count - 1]
    }

    /// All elements as a regular array.
    public var elements: [Element] { [_first] + _rest }

    /// The number of elements in the array (always >= 1).
    public var count: Int { _rest.count + 1 }

    /// Whether the array contains only one element.
    public var isSingle: Bool { _rest.isEmpty }

    /// Access an element by index.
    /// - Parameter index: The index of the element
    /// - Returns: The element at the specified index
    /// - Precondition: `index` must be within bounds
    public subscript(index: Int) -> Element {
        precondition(index >= 0 && index < count, "Index out of bounds")
        return index == 0 ? _first : _rest[index - 1]
    }

    /// Maps the elements to a new type.
    /// - Parameter transform: The transformation function
    /// - Returns: A new NonEmptyArray with transformed elements
    public func map<T>(_ transform: (Element) -> T) -> NonEmptyArray<T> {
        NonEmptyArray<T>(transform(_first), _rest.map(transform))
    }

    /// Filters the elements based on a predicate.
    /// - Parameter isIncluded: The predicate to filter by
    /// - Returns: A new NonEmptyArray if at least one element passes the filter, `nil` otherwise
    public func filter(_ isIncluded: (Element) -> Bool) -> NonEmptyArray<Element>? {
        let filtered = elements.filter(isIncluded)
        return NonEmptyArray(filtered)
    }

    /// Appends an element to the end of the array.
    /// - Parameter element: The element to append
    /// - Returns: A new NonEmptyArray with the appended element
    public func appending(_ element: Element) -> NonEmptyArray<Element> {
        NonEmptyArray(_first, _rest + [element])
    }

    /// Prepends an element to the beginning of the array.
    /// - Parameter element: The element to prepend
    /// - Returns: A new NonEmptyArray with the prepended element
    public func prepending(_ element: Element) -> NonEmptyArray<Element> {
        NonEmptyArray(element, [_first] + _rest)
    }
}

// MARK: - Collection Conformance
extension NonEmptyArray: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public func index(after index: Int) -> Int {
        index + 1
    }
}

// MARK: - Equatable Conformance
extension NonEmptyArray: Equatable where Element: Equatable {
    public static func == (lhs: NonEmptyArray<Element>, rhs: NonEmptyArray<Element>) -> Bool {
        lhs.elements == rhs.elements
    }
}

// MARK: - Hashable Conformance
extension NonEmptyArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}

// MARK: - CustomStringConvertible Conformance
extension NonEmptyArray: CustomStringConvertible {
    public var description: String {
        "NonEmptyArray(\(elements))"
    }
}

// MARK: - CustomDebugStringConvertible Conformance
extension NonEmptyArray: CustomDebugStringConvertible {
    public var debugDescription: String {
        "NonEmptyArray<\(Element.self)>(\(elements))"
    }
}
