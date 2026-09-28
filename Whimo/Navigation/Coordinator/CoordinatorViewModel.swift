//
//  CoordinatorViewModel.swift
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

import SwiftUI
import Combine
import FlowStacks
import class Utility.CancelBag

private typealias Module = CoordinatorModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel<Screen: AnyScreen>: ObservableObject {
        // MARK: - Public Properties
        @Published private(set) var path: Routes<Screen> = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState

        // MARK: - Private Properties
        private let navigationHandler: NavigationHandler<Screen>
        private let cancellable: CancelBag = .init()

        // MARK: - Init
        init(navigationHandler: NavigationHandler<Screen>) {
            self.navigationHandler = navigationHandler
            navigationHandler.$path
                .weakAssign(on: self, to: \.path)
                .store(in: cancellable)
        }

        // MARK: - Public Methods
        func setNavigationPath(_ path: Routes<Screen>) {
            navigationHandler.setNavigationPath(path)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel { }
