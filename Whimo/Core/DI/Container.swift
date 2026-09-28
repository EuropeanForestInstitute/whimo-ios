//
//  Container.swift
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
import FactoryKit
import RestClient

typealias AppContainer = Container
typealias Inject = Injected

extension AppContainer: @retroactive AutoRegistering {
    public func autoRegister() {
        manager.defaultScope = .singleton

        restClient.register { self.makeRestClient() }
    }
}

extension AppContainer {
    func makeRestClient(baseURL: URL = ApiConfiguration.baseUrl, configuration: URLSessionConfiguration? = nil) -> RestClient {
        let client = RestClient(baseURL: baseURL, connectivity: connectivity.resolve(), userDefaults: userDefaultsStore.resolve(),
            configuration: configuration)
        let modes = businessModeRepository.resolve()
        let context = businessDataContext.resolve()
        client.requestContextProvider = { requestPath, method in
            let path = requestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.hasPrefix("auth/") || (path == "users/profile" && method == .get) {
                return .init(baseURL: baseURL)
            }
            let generation = try? context.capture()
            let isTest = modes.mode == .test
            return .init(baseURL: isTest ? baseURL.appendingPathComponent("test") : baseURL,
                         handlesUnauthorized: !isTest, validate: {
                guard let generation else { throw CancellationError() }

                try generation.check()
            })
        }
        client.clientErrorWorker = restClientErrorWorker.resolve()
        return client
    }
}
