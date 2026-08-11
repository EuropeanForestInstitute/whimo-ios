//
//  ConnectivityImpl.swift
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
import Alamofire
import Combine

public class ConnectivityImpl: Connectivity {
    public typealias Status = NetworkReachabilityManager.NetworkReachabilityStatus

    // MARK: - Public Properties
    public var isReachable: AnyPublisher<Status, Never> { _isReachable.eraseToAnyPublisher() }
    public var isReachableValue: Status { _isReachable.value }
    public var isReachableFlag: Bool {
        if case .reachable = _isReachable.value {
            true
        } else {
            false
        }
    }

    // MARK: - Private Properties
    private let manager: NetworkReachabilityManager? = .init()
    private var _isReachable: CurrentValueSubject<Status, Never> = .init(.unknown)

    // MARK: - Init
    public init() {
        configure()
    }

    // MARK: - Public Methods
    public func startObserving() {
        manager?.startListening { [weak self] status in
            guard let self = self else { return }

            self._isReachable.send(status)
        }
    }

    public func stopObserving() {
        manager?.stopListening()
    }

    // MARK: - Private Methods
    private func configure() {
        if let status = manager?.status {
            _isReachable.send(status)
        }
    }
}
