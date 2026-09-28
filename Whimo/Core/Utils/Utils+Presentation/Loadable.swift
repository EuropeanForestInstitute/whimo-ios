//
//  Loadable.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.06.2025.
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

/// A state machine enum for managing asynchronous data loading operations.
///
/// `Loadable<T>` provides a type-safe way to represent all possible states of async data:
/// from initial state through loading, to success or failure. Each state can optionally
/// preserve previous data to enable smooth UI transitions.
///
/// ## Typical Lifecycle Flow:
///
/// ```
/// .notRequested
///     ↓ (cache load)
/// .requested(lastValue: cachedData)
///     ↓ (network call starts)
/// .isLoading(lastValue: cachedData)
///     ↓ (success)
/// .loaded(value: freshData)
///
///     OR
///
///     ↓ (failure)
/// .failed(error: error)
/// ```
///
/// ## Common Usage Patterns:
///
/// **Service Layer (loading from cache):**
/// ```swift
/// // 1. Load from local cache
/// state.list.setIsLoading()
/// let cachedData = try await localRepo.fetch()
/// state.list = .requested(lastValue: cachedData) // Signal: cache ready, need server update
///
/// // 2. Fetch from server
/// state.list.setIsLoading()
/// let freshData = try await remoteRepo.fetch()
/// state.list = .loaded(value: freshData) // Done: fresh data loaded
/// ```
///
/// **ViewModel Layer (observing state):**
/// ```swift
/// appState.profile.state
///     .map(\.userModel)
///     .sink { loadableUser in
///         switch loadableUser {
///         case .notRequested, .requested:
///             break // No UI update needed
///         case .isLoading(let lastValue):
///             if let lastValue {
///                 self.userProfile = .init(from: lastValue) // Show cached data
///             }
///         case .loaded(let value):
///             self.userProfile = .init(from: value) // Show fresh data
///         case .failed(let error):
///             self.showError(message: error.localizedDescription)
///         }
///     }
/// ```
enum Loadable<T: Equatable> {
    /// Initial state: no data fetch has been initiated yet.
    ///
    /// **When to use:**
    /// - As the default initial state in State objects
    /// - After user logs out or data is cleared
    /// - When resetting a feature to its initial state
    ///
    /// **Example from codebase:**
    /// ```swift
    /// // ProfileState.swift
    /// var userModel: Loadable<UserModel> = .notRequested
    /// ```
    case notRequested

    /// Cached data is available and awaiting fresh data from server.
    ///
    /// **When to use:**
    /// - After successfully loading data from local cache/database
    /// - Signals that UI should display cached data while server fetch is triggered
    /// - When user triggers refresh but you want to keep showing old data
    ///
    /// **Primary pattern (cache services):**
    /// ```swift
    /// // TransactionsCacheServiceImpl.swift
    /// let cachedTransactions = try await localRepo.fetchTransactions()
    /// state.list = .requested(lastValue: cachedTransactions)
    /// // Next step: trigger network fetch to get fresh data
    /// ```
    ///
    /// **Secondary pattern (user-triggered refresh):**
    /// ```swift
    /// // HomeViewModel.swift - user changes filter
    /// appState.transactions[\.list] = .requested(lastValue: nil)
    /// await fetchData(searchData: searchData, refresh: true)
    /// ```
    ///
    /// - Parameter lastValue: Optional cached/previous data to display while fetching fresh data
    case requested(lastValue: T?)

    /// Actively loading data from network or database.
    ///
    /// **When to use:**
    /// - Immediately before making a network call or database query
    /// - To show loading indicators in UI
    /// - Preserves previous data so UI doesn't flicker during refresh
    ///
    /// **Example from codebase:**
    /// ```swift
    /// // ProfileServiceImpl.swift
    /// appState.profile.dispatch { state in
    ///     state.userModel.setIsLoading() // Preserves existing value
    /// }
    /// let user = try await profileRepository.fetchProfile()
    /// appState.profile.dispatch { state in
    ///     state.userModel = .loaded(value: user)
    /// }
    /// ```
    ///
    /// **ViewModel usage:**
    /// ```swift
    /// // HomeViewModel.swift
    /// case .isLoading:
    ///     self.appState.system[\.isLoading] = true // Show spinner
    /// ```
    ///
    /// - Parameter lastValue: Optional previous data to keep displaying during loading
    case isLoading(lastValue: T?)

    /// Data successfully loaded and ready to use.
    ///
    /// **When to use:**
    /// - After successful network request or database query
    /// - Represents the happy path of data fetching
    /// - Contains the fresh, validated data
    ///
    /// **Example from codebase:**
    /// ```swift
    /// // ProfileServiceImpl.swift
    /// let user = try await profileCachingRepository.fetchProfile()
    /// appState.profile.dispatch { state in
    ///     state.userModel = .loaded(value: user)
    /// }
    /// ```
    ///
    /// **ViewModel extraction:**
    /// ```swift
    /// // AccountInfoViewModel.swift
    /// case .loaded(let value):
    ///     self.userProfile = .init(from: value) // Update UI with fresh data
    /// ```
    ///
    /// - Parameter value: The successfully loaded data
    case loaded(value: T)

    /// Data fetch failed with an error.
    ///
    /// **When to use:**
    /// - After a network request fails
    /// - When database query throws an error
    /// - To communicate what went wrong to the user
    ///
    /// **Example from codebase:**
    /// ```swift
    /// // ProfileServiceImpl.swift
    /// do {
    ///     let user = try await profileCachingRepository.fetchProfile()
    ///     state.userModel = .loaded(value: user)
    /// } catch {
    ///     state.userModel = .failed(error: error)
    ///     throw error
    /// }
    /// ```
    ///
    /// **ViewModel error handling:**
    /// ```swift
    /// // AccountInfoViewModel.swift
    /// case .failed(let error):
    ///     self.appState.showError(message: error.localizedDescription)
    /// ```
    ///
    /// - Parameter error: The error that caused the failure
    case failed(error: Error)

    // MARK: - Computed Properties

    /// Extracts the value from any state that contains data.
    ///
    /// Returns the associated value from `.requested`, `.isLoading`, or `.loaded` states.
    /// Returns `nil` for `.notRequested` and `.failed` states.
    ///
    /// **Example:**
    /// ```swift
    /// let loadableUser: Loadable<UserModel> = .loaded(value: user)
    /// if let user = loadableUser.value {
    ///     print(user.username) // Access user data regardless of specific state
    /// }
    /// ```
    var value: T? {
        switch self {
            case .requested(let lastValue): return lastValue
            case .isLoading(let lastValue): return lastValue
            case .loaded(let value): return value
            default: return nil
        }
    }

    /// Extracts the error from a failed state.
    ///
    /// Returns the error if in `.failed` state, otherwise returns `nil`.
    ///
    /// **Example:**
    /// ```swift
    /// if let error = loadableData.error {
    ///     showAlert(error.localizedDescription)
    /// }
    /// ```
    var error: Error? {
        switch self {
            case .failed(let error): return error
            default: return nil
        }
    }

    /// Checks if data is currently being loaded.
    ///
    /// **Example:**
    /// ```swift
    /// if transactions.isLoading {
    ///     showLoadingSpinner()
    /// }
    /// ```
    var isLoading: Bool {
        switch self {
            case .isLoading: return true
            default: return false
        }
    }

    /// Checks if data has been successfully loaded.
    ///
    /// **Example:**
    /// ```swift
    /// if userProfile.isLoaded {
    ///     enableProfileEditButton()
    /// }
    /// ```
    var isLoaded: Bool {
        switch self {
            case .loaded: return true
            default: return false
        }
    }

    /// Human-readable description of the current state for debugging.
    ///
    /// Useful for logging and debugging data flow issues.
    ///
    /// **Example:**
    /// ```swift
    /// log.debug("User state: \(userModel.desc)")
    /// // Output: "loaded. UserModel(...)" or "isLoading. lastValue: true"
    /// ```
    var desc: String {
        switch self {
            case .notRequested:
                "notRequested"
            case .requested(let lastValue):
                "requested. lastValue: \(lastValue != nil)"
            case .isLoading(let lastValue):
                "isLoading. lastValue: \(lastValue != nil)"
            case .loaded(let value):
                "loaded. \(value)"
            case .failed(let error):
                "failed. \(error.localizedDescription)"
        }
    }
}

// MARK: - Loadable Mutation Methods
extension Loadable {
    /// Transitions to `.isLoading` state while preserving the current value.
    ///
    /// Called by services before initiating async operations (network calls, database queries).
    /// Preserves any existing data so the UI can continue displaying it during loading.
    ///
    /// **Example from codebase:**
    /// ```swift
    /// // ProfileServiceImpl.swift
    /// appState.profile.dispatch { state in
    ///     state.userModel.setIsLoading() // .loaded(user) → .isLoading(lastValue: user)
    /// }
    /// let freshUser = try await profileRepository.fetchProfile()
    /// state.userModel = .loaded(value: freshUser)
    /// ```
    mutating func setIsLoading() {
        self = .isLoading(lastValue: value)
    }

    /// Cancels the loading operation and restores appropriate state.
    ///
    /// If there was cached data, restores to `.loaded(value:)`.
    /// If no cached data existed, reverts to `.notRequested`.
    ///
    /// **Use cases:**
    /// - User cancels a long-running request
    /// - Network request times out and you want to revert to cached data
    /// - Operation is interrupted by user navigation
    ///
    /// **Example:**
    /// ```swift
    /// func cancelUserProfileFetch() {
    ///     appState.profile.dispatch { state in
    ///         state.userModel.cancelLoading()
    ///         // If had cached user → .loaded(value: cachedUser)
    ///         // If no cached user → .notRequested
    ///     }
    /// }
    /// ```
    mutating func cancelLoading() {
        switch self {
            case let .isLoading(lastValue):
                if let lastValue = lastValue {
                    self = .loaded(value: lastValue)
                } else {
                    self = .notRequested
                }
            default: break
        }
    }

    /// Transforms the wrapped value type while preserving the loading state.
    ///
    /// Applies a transformation function to the associated value in each case,
    /// maintaining the same loading state but with a new value type.
    /// If the transformation throws, returns `.failed(error:)`.
    ///
    /// **Use case:**
    /// - Converting between domain models and view models
    /// - Extracting specific properties from loaded data
    /// - Applying calculations to loaded values
    ///
    /// **Example:**
    /// ```swift
    /// // Transform Loadable<UserModel> to Loadable<String>
    /// let loadableUser: Loadable<UserModel> = .loaded(value: user)
    /// let loadableUsername: Loadable<String> = loadableUser.map { $0.username }
    /// // Result: .loaded(value: "John Doe")
    ///
    /// // Works with all states:
    /// let loading: Loadable<UserModel> = .isLoading(lastValue: cachedUser)
    /// let loadingName = loading.map { $0.username }
    /// // Result: .isLoading(lastValue: "Jane Doe")
    /// ```
    ///
    /// - Parameter transform: A closure that transforms the wrapped value
    /// - Returns: A new `Loadable` with transformed value type
    func map<V>(_ transform: (T) throws -> V) -> Loadable<V> {
        do {
            switch self {
                case .notRequested: return .notRequested
                case let .requested(lastValue):
                    return .requested(
                        lastValue: try lastValue.map { try transform($0) }
                    )
                case .isLoading(let lastValue):
                    return .isLoading(
                        lastValue: try lastValue.map { try transform($0) }
                    )
                case .loaded(let value):
                    return .loaded(value: try transform(value))
                case .failed(let error): return .failed(error: error)
            }
        } catch {
            return .failed(error: error)
        }
    }
}

// MARK: - Optional Unwrapping Support

/// Protocol enabling safe unwrapping of optional values.
///
/// Used internally by `Loadable` to provide type-safe unwrapping
/// of optional wrapped values via the `.unwrap()` method.
protocol SomeOptional {
    associatedtype Wrapped
    func unwrap() throws -> Wrapped
}

/// Error thrown when attempting to unwrap a `nil` optional value.
///
/// Provides a localized error message for better UX when optional
/// unwrapping fails in the context of `Loadable`.
struct ValueIsMissingError: Error {
    var localizedDescription: String {
        NSLocalizedString("Data is missing", comment: "")
    }
}

extension Optional: SomeOptional {
    /// Unwraps the optional value or throws if `nil`.
    ///
    /// - Returns: The wrapped value
    /// - Throws: `ValueIsMissingError` if the value is `nil`
    func unwrap() throws -> Wrapped {
        switch self {
            case let .some(value): return value
            case .none: throw ValueIsMissingError()
        }
    }
}

// MARK: - Loadable Optional Unwrapping
extension Loadable where T: SomeOptional, T.Wrapped: Equatable {
    /// Unwraps optional values within `Loadable`.
    ///
    /// Transforms `Loadable<Optional<T>>` to `Loadable<T>` by unwrapping the optional.
    /// If unwrapping fails (value is `nil`), returns `.failed(error: ValueIsMissingError)`.
    ///
    /// **Use case:**
    /// - Converting `Loadable<User?>` to `Loadable<User>`
    /// - Ensuring loaded data is non-nil before processing
    ///
    /// **Example:**
    /// ```swift
    /// let optionalUser: Loadable<UserModel?> = .loaded(value: user)
    /// let requiredUser: Loadable<UserModel> = optionalUser.unwrap()
    /// // If user is nil → .failed(error: ValueIsMissingError())
    /// // If user exists → .loaded(value: user)
    /// ```
    func unwrap() -> Loadable<T.Wrapped> {
        map { try $0.unwrap() }
    }
}

// MARK: - Equatable Conformance
extension Loadable: Equatable {
    /// Compares two `Loadable` instances for equality.
    ///
    /// Two `Loadable` values are equal if:
    /// - Both are in the same state (e.g., both `.loaded`)
    /// - Their associated values are equal (for states that have values)
    /// - For `.failed`, errors are compared by their `localizedDescription`
    ///
    /// **Example:**
    /// ```swift
    /// let user1: Loadable<User> = .loaded(value: user)
    /// let user2: Loadable<User> = .loaded(value: user)
    /// print(user1 == user2) // true
    ///
    /// let loading1: Loadable<User> = .isLoading(lastValue: nil)
    /// let loading2: Loadable<User> = .isLoading(lastValue: user)
    /// print(loading1 == loading2) // false (different lastValue)
    /// ```
    static func == (lhs: Loadable<T>, rhs: Loadable<T>) -> Bool {
        switch (lhs, rhs) {
            case (.notRequested, .notRequested): return true
            case let (.requested(lhsV), .requested(rhsV)): return lhsV == rhsV
            case let (.isLoading(lhsV), .isLoading(rhsV)): return lhsV == rhsV
            case let (.loaded(lhsV), .loaded(rhsV)): return lhsV == rhsV
            case let (.failed(lhsE), .failed(rhsE)):
                return lhsE.localizedDescription == rhsE.localizedDescription
            default: return false
        }
    }
}
