//
//  AutoStringConvertible.swift
//  Utility
//
//  Created by Vyacheslav Razumeenko on 20.05.2025.
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

// MARK: - Mirror+Extension
extension Mirror {
    static func reflectingProperties(of target: Any) -> [String: Any] {
        reflectProperties(of: target, matchingType: Any.self)
    }

    static func reflectProperties<T>(
        of target: Any,
        matchingType: T.Type = T.self
    ) -> [String: T] {
        let mirror: Mirror = .init(reflecting: target)
        var result: [String: T] = .init()

        let childrens = mirror.children
        for child in childrens {
            guard let label = child.label,
                  let value = child.value as? T else { continue }
            result[label] = value
        }

        return result
    }
}

// MARK: - AutoStringConvertible
public protocol AutoStringConvertible: CustomStringConvertible {
    func customDescription(nestingLevel: Int) -> String
}

public extension AutoStringConvertible {
    var description: String {
        customDescription(nestingLevel: .zero)
    }

    func customDescription(nestingLevel: Int) -> String {
        let content: [String: Any] = Mirror.reflectingProperties(of: self)
        let sortedKeys: [String] = content.keys.sorted()
        var contentResult: String = .init()

        for field in sortedKeys {
            if let value = content[field] {
                // swiftlint:disable:next identifier_name
                var _value = "\(value)"
                if let autoValue: AutoStringConvertible = value as? AutoStringConvertible {
                    _value = autoValue.customDescription(nestingLevel: nestingLevel + 1)
                }
                if let arrayValue: Array = value as? [Any] {
                    _value = "["

                    for item in arrayValue {
                        // swiftlint:disable:next identifier_name
                        var _arrayItem: String = _value.count > 1 ? ",\n\(gap(nesting: nestingLevel + 2))" : "\n\(gap(nesting: nestingLevel + 2))"
                        if let autoValue: AutoStringConvertible = item as? AutoStringConvertible {
                            _arrayItem += autoValue.customDescription(nestingLevel: nestingLevel + 2)

                        } else {
                            _arrayItem += "\(item)"
                        }
                        _value += _arrayItem
                    }

                    _value += _value.count > 1 ? "\n\(gap(nesting: nestingLevel + 1))]" : "]"
                }
                contentResult += "\(contentResult.isEmpty ? "" : ",\n")\(gap(nesting: nestingLevel + 1))\"\(field)\": \(type(of: value)) = \(_value)"
            }
        }

        let result: String = nestingLevel == .zero
        ? "\(type(of: self)) = {\n\(contentResult)\n\(gap(nesting: nestingLevel))}"
        : "{\n\(contentResult)\n\(gap(nesting: nestingLevel))}"
        return result
    }

    private func gap(nesting: Int) -> String {
        [String](
            repeating: " ",
            count: nesting * 3
        ).joined()
    }
}
