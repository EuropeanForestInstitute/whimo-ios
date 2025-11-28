//
//  Publisher+Extension.swift
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

import Combine
import SwiftUI

// MARK: - Publisher+Assign
extension Publisher where Failure == Never {
    public func animatedAssign<Root: AnyObject>(
        on object: Root,
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        animation: Animation? = .default
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { [weak object] value in
                withAnimation(animation) {
                    object?[keyPath: keyPath] = value
                }
            }
    }

    public func weakAssign<Root: AnyObject>(
        on object: Root,
        to keyPath: ReferenceWritableKeyPath<Root, Output>
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
    }

    public func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Publishers.SetFailureType<Self, Error>> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - Publisher+DefaultDebounce
extension Publisher {
    public func defaultDebounce<S>(
        scheduler: S = DispatchQueue.main,
        options: S.SchedulerOptions? = nil
    ) -> Publishers.Debounce<Self, S> where S: Scheduler {
        self.debounce(for: .seconds(0.3), scheduler: scheduler)
    }
}
