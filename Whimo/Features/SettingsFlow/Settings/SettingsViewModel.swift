//
//  SettingsViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 05.05.2025.
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
import Utility
import enum Resources.LocalizeKeys

private typealias Module = SettingsModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var connectionReachable: Bool = true

        var list: IdentifiedArrayOf<Row> { .init(uniqueElements: Row.allCases) }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.connectivity) private var connectivity

        // MARK: - Init
        init() {
            setupBinding()
        }

        // MARK: - ViewModelProtocol
    }
}

// MARK: - Private Methods
private extension ViewModel {
    func setupBinding() {
        connectivity.isReachable
            .receive(on: DispatchQueue.main)
            .map { status in
                switch status {
                    case .notReachable:
                        return false
                    case .reachable:
                        return true
                    case .unknown:
                        return true
                }
            }
            .animatedAssign(on: self, to: \.connectionReachable)
            .store(in: cancellable)
    }
}
