//
//  ChangeLanguageViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.04.2025.
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
import StorageKit
import enum Resources.LocalizeKeys

private typealias Module = ChangeLanguageModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var languages: [Model] = []
        @Published private(set) var selectedLanguage: Model = .init(localize: .english)

        // MARK: - Private Properties
        @AppStorage(.currentLocalize) private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.userDefaultsStore) private var userDefaultsStore

        // MARK: - Init
        init() {
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapChange(language: Model) {
            currentLocalize = language.localize
            userDefaultsStore.set(language.localize, key: .currentLocalize)
            fetchSelectedLanguage()
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func startup() {
        fetchLanguagesList()
        fetchSelectedLanguage()
    }

    // MARK: - Common
    func fetchLanguagesList() {
        let languages: [Module.Model] = LocalizeKeys.allCases.map { .init(localize: $0) }
        self.languages = languages
    }

    func fetchSelectedLanguage() {
        self.selectedLanguage = .init(localize: currentLocalize)
    }
}
