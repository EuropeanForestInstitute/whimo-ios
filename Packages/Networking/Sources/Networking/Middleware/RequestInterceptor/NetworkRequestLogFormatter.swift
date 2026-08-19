//
//  NetworkRequestLogFormatter.swift
//  Whimo
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

#if DEBUG
import Foundation

// MARK: - NetworkRequestLogFormatter
enum NetworkRequestLogFormatter {
    static func message(for request: URLRequest) -> String {
        let queryParameters = parameterList(queryParameterNames(in: request))
        let headerFields = parameterList(
            request.allHTTPHeaderFields.map { Array($0.keys) } ?? []
        )
        let bodyParameters = bodyParameterDescription(for: request)

        return """
        Request: \(request.httpMethod ?? "nil")
        Query parameters: \(queryParameters)
        Header fields: \(headerFields)
        Body parameters: \(bodyParameters)
        """
    }
}

// MARK: - Private Methods
private extension NetworkRequestLogFormatter {
    static func queryParameterNames(in request: URLRequest) -> [String] {
        guard
            let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return [] }

        return components.queryItems?.map(\.name) ?? []
    }

    static func bodyParameterDescription(for request: URLRequest) -> String {
        guard let body = request.httpBody, !body.isEmpty else { return "<none>" }

        if let object = try? JSONSerialization.jsonObject(
            with: body,
            options: .fragmentsAllowed
        ) {
            return parameterList(jsonParameterNames(in: object))
        }

        if request.value(forHTTPHeaderField: "Content-Type")?
            .localizedCaseInsensitiveContains("application/x-www-form-urlencoded") == true {
            return parameterList(formParameterNames(in: body))
        }

        return "<raw body redacted>"
    }

    static func formParameterNames(in data: Data) -> [String] {
        guard let form = String(data: data, encoding: .utf8) else { return [] }

        var components = URLComponents()
        components.percentEncodedQuery = form
        return components.queryItems?.map(\.name) ?? []
    }

    static func jsonParameterNames(
        in value: Any,
        prefix: String? = nil
    ) -> [String] {
        if let dictionary = value as? [String: Any] {
            return dictionary.flatMap { key, nestedValue in
                let path = prefix.map { "\($0).\(key)" } ?? key
                let nestedNames = jsonParameterNames(in: nestedValue, prefix: path)
                return nestedNames.isEmpty ? [path] : nestedNames
            }
        }

        if let array = value as? [Any] {
            let path = prefix.map { "\($0)[]" }
            let nestedNames = array.flatMap { jsonParameterNames(in: $0, prefix: path) }
            return nestedNames.isEmpty ? path.map { [$0] } ?? [] : nestedNames
        }

        return prefix.map { [$0] } ?? []
    }

    static func parameterList<S: Sequence>(_ names: S) -> String where S.Element == String {
        let uniqueNames = Set(names).sorted()
        return uniqueNames.isEmpty ? "<none>" : uniqueNames.joined(separator: ", ")
    }
}
#endif
