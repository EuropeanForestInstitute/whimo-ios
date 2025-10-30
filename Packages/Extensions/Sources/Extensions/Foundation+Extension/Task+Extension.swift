//
//  Task+Extension.swift
//  Extensions
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

extension Task where Failure == Never, Success == Void {
    @discardableResult
    /// Usage example:
    /// ```
    /// Task {
    ///     let requestModel: RequestModels.SignUpModel = .init(userName: phoneNumber, password: password)
    ///     let resultModel = try await self.authService.signUp(requestModel)
    ///     self.saveUser(model: resultModel)
    /// } catch: { error in
    ///     AppLog.error(error.localizedDescription)
    /// }
    /// ```
    public init(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Void,
        `catch`: @escaping (Error) -> Void
    ) {
        self.init(priority: priority) {
            do {
                _ = try await operation()
            } catch {
                `catch`(error)
            }
        }
    }

    @discardableResult
    public init(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Void,
        `catchInMain`: @escaping (Error) -> Void
    ) {
        self.init(priority: priority) {
            do {
                _ = try await operation()
            } catch {
                await MainActor.run {
                    `catchInMain`(error)
                }
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for at least the given duration
    /// in seconds.
    ///
    /// If the task is canceled before the time ends,
    /// this function throws `CancellationError`.
    ///
    /// This function doesn't block the underlying thread.
    public static func sleep(seconds: Double) async throws {
        if #available(iOS 16.0, *) {
            try await sleep(for: .seconds(seconds))
        } else {
            try await sleep(nanoseconds: UInt64(seconds * 1000) * NSEC_PER_MSEC)
        }
    }
}
