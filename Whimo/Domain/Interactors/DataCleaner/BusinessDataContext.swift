//
//  BusinessDataContext.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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

/// A reset invalidates in-flight business reads and writes even when the participant stays signed in.
/// Task-local propagation keeps nested repository calls on the generation captured by their caller.
final class BusinessDataContext {
    final class Generation {
        private let lock = NSRecursiveLock()
        private var isCurrent = true

        func invalidate() { lock.withLock { isCurrent = false } }

        func check() throws {
            try Task.checkCancellation()
            try whileCurrent { }
        }

        func whileCurrent<Value>(_ operation: () throws -> Value) throws -> Value {
            try lock.withLock {
                guard isCurrent else { throw CancellationError() }

                return try operation()
            }
        }
    }

    @TaskLocal static var requestGeneration: Generation?
    private let lock = NSLock()
    private var generation = Generation()
    private var isResetting = false
    private var protectedWork: [ObjectIdentifier: Int] = [:]

    func capture() throws -> Generation {
        try Task.checkCancellation()
        let captured = try lock.withLock {
            guard !isResetting else { throw CancellationError() }

            return Self.requestGeneration ?? generation
        }
        try captured.check()
        return captured
    }

    func withCurrentGeneration<Value>(_ operation: () async throws -> Value) async throws -> Value {
        let captured = try capture()
        return try await Self.$requestGeneration.withValue(captured) {
            do {
                let value = try await operation()
                try captured.check()
                return value
            } catch {
                // Restore cancellation if a database/transport wrapper changed the error type.
                try captured.check()
                throw error
            }
        }
    }

    func commit<Value>(_ operation: () throws -> Value) throws -> Value {
        try capture().whileCurrent(operation)
    }

    @MainActor
    func commitState(_ operation: @MainActor () throws -> Void) throws {
        try commit(operation)
    }

    var hasProtectedWork: Bool {
        lock.withLock { (protectedWork[ObjectIdentifier(generation)] ?? 0) > 0 }
    }

    func withProtectedWork<Value>(_ operation: () async throws -> Value) async throws -> Value {
        let captured = try capture()
        let identity = ObjectIdentifier(captured)
        try lock.withLock {
            guard !isResetting, captured === generation else { throw CancellationError() }

            protectedWork[identity, default: 0] += 1
        }
        defer {
            lock.withLock {
                protectedWork[identity, default: 1] -= 1
                if protectedWork[identity] == 0 { protectedWork.removeValue(forKey: identity) }
            }
        }
        return try await Self.$requestGeneration.withValue(captured) {
            try await withCurrentGeneration(operation)
        }
    }

    func beginReset(protectingUnsynchronizedWork: Bool = false) throws {
        let discarded = try lock.withLock {
            guard !isResetting else { throw CancellationError() }

            if protectingUnsynchronizedWork, (protectedWork[ObjectIdentifier(generation)] ?? 0) > 0 {
                throw BusinessModeError.synchronizationRequired
            }
            isResetting = true
            return generation
        }
        // No context lock is held while a synchronous database/file/state commit finishes.
        discarded.invalidate()
    }

    func finishReset() {
        lock.withLock {
            generation = Generation()
            isResetting = false
        }
    }
}
