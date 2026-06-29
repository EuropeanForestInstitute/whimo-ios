//
//  Container+AppState.swift
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

import FactoryKit
import RestClient

extension AppContainer {
    // MARK: - Lifecycle
    var appState: Factory<AppState> {
        self {
            AppStateImpl(
                system: .init(inititalValue: .initialState),
                navigation: .init(inititalValue: .initialState),
                transactions: .init(inititalValue: .initialState),
                balance: .init(inititalValue: .initialState),
                createTransaction: .init(inititalValue: .initialState),
                createPassword: .init(inititalValue: .initialState),
                notifications: .init(inititalValue: .initialState),
                notificationsSettings: .init(inititalValue: .initialState),
                profile: .init(inititalValue: .initialState),
                toastManager: self.toastManager.resolve(),
                hapticsEngineService: self.hapticsEngineService.resolve()
            )
        }
        .onPreview {
            AppStateImpl(
                system: .init(inititalValue: .preview),
                navigation: .init(inititalValue: .preview),
                transactions: .init(inititalValue: .preview),
                balance: .init(inititalValue: .preview),
                createTransaction: .init(inititalValue: .preview),
                createPassword: .init(inititalValue: .preview),
                notifications: .init(inititalValue: .preview),
                notificationsSettings: .init(inititalValue: .preview),
                profile: .init(inititalValue: .preview),
                toastManager: self.toastManager.resolve(),
                hapticsEngineService: self.hapticsEngineService.resolve()
            )
        }
    }

    var restClientErrorWorker: Factory<RestClientErrorWorker> {
        self { RestClientErrorWorkerImpl() }
    }
}
