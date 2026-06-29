//
//  StateStore.swift
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
import Combine
import Utility

// MARK: - StateSubject
typealias StateSubject<State: AnyState> = CurrentValueSubject<State, Never>

// MARK: - StateStore
class StateStore<State: AnyState> {
    typealias Activity = State.Activity

    // MARK: - Properties
    var state: AnyPublisher<State, Never> {
        _state.eraseToAnyPublisher()
    }
    var activity: AnyPublisher<Activity, Never> {
        _activity.eraseToAnyPublisher()
    }

    var value: State { _state.value }

    // MARK: - Private Properties
    private let _state: StateSubject<State>
    private let _activity: PassthroughSubject<Activity, Never> = .init()
    private let lock: NSLock = .init()

    // MARK: - Init
    init(inititalValue: State = .initialState) {
        self._state = .init(inititalValue)
    }

    // MARK: - Methods
    func dispatch(
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        _ commit: (inout State) -> Void
    ) {
        lock.lock()
        defer { lock.unlock() }

        var value = _state.value
        commit(&value)

        guard _state.value != value else {
            log.debug(
                "\(type(of: value)) is not updated",
                file: file,
                function: function,
                line: line
            )
            return
        }

        _state.send(value)
    }

    func send(_ activity: Activity) {
        _activity.send(activity)
    }
}

// MARK: - KeyPath
extension StateStore {
    subscript<T>(
        keyPath: WritableKeyPath<State, T>,
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line
    ) -> T where T: Equatable {
        get { value[keyPath: keyPath] }
        set {
            dispatch(file: file, function: function, line: line) { state in
                state[keyPath: keyPath] = newValue
            }
        }
    }
}
