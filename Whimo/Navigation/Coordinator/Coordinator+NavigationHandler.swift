//
//  Coordinator+NavigationHandler.swift
//  Whimo
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
import SwiftUI
import Combine
import FlowStacks
import var Utility.log
import class Utility.CancelBag
import protocol Utility.AutoStringConvertible

// MARK: - PrintArray
private struct PrintArray<T>: AutoStringConvertible {
    let elements: [T]
}

private typealias Module = CoordinatorModule

// MARK: - NavigationHandler
extension Module {
    final class NavigationHandler<Screen: AnyScreen>: ObservableObject {
        // MARK: - Public Properties
        @Published private(set) var path: Routes<Screen> = .init() {
            didSet {
                var message = "Top View did update."
                message.append("\nCurrent navigation::\(PrintArray(elements: path))")
                log.debug(message)
            }
        }

        // MARK: - Private Properties
        private let cancellable: CancelBag = .init()
        private var output: (Routes<Screen>) -> Void

        // MARK: - Init
        init(input: AnyPublisher<Routes<Screen>, Never>, output: @escaping (Routes<Screen>) -> Void) {
            self.output = output
            input
                .weakAssign(on: self, to: \.path)
                .store(in: cancellable)
        }

        // MARK: - Public Methods
        func setNavigationPath(_ path: Routes<Screen>) {
            log.debug()
            output(path)
        }
    }
}
