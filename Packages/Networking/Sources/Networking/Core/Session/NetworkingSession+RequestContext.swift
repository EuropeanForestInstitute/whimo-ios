//
//  NetworkingSession+RequestContext.swift
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

extension NetworkingSession {
    /// Captured once for each asynchronous request, including its response/error delivery.
    public struct RequestContext {
        public let baseURL: URL
        public let handlesUnauthorized: Bool
        public let validate: () throws -> Void

        public init(baseURL: URL, handlesUnauthorized: Bool = true, validate: @escaping () throws -> Void = {}) {
            self.baseURL = baseURL
            self.handlesUnauthorized = handlesUnauthorized
            self.validate = validate
        }
    }

    @TaskLocal static var activeRequestContext: RequestContext?

    public func withRequestContext<Value>(_ context: RequestContext, operation: () async throws -> Value) async throws -> Value {
        try context.validate()
        return try await Self.$activeRequestContext.withValue(context) {
            do {
                let value = try await operation()
                try context.validate()
                return value
            } catch {
                try context.validate()
                throw error
            }
        }
    }
}
