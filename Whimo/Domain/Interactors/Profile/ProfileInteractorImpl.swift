//
//  ProfileInteractorImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 17.07.2025.
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

final class ProfileInteractorImpl: ProfileInteractor {
    // MARK: - Dependencies
    private let appState: AppState
    private let profileCachingRepository: any ProfileCachingRepository
    private let profileLocalRepository: ProfileLocalRepository

    // MARK: - Init
    init(
        appState: AppState,
        profileCachingRepository: any ProfileCachingRepository,
        profileLocalRepository: ProfileLocalRepository
    ) {
        self.appState = appState
        self.profileCachingRepository = profileCachingRepository
        self.profileLocalRepository = profileLocalRepository
    }

    // MARK: - ProfileInteractor

    /// Fetches profile from network with cache fallback
    /// Uses CachingRepository which handles network + cache strategy
    func fetchProfile() async throws {
        appState.profile.dispatch { state in
            state.userModel.setIsLoading()
        }

        do {
            // Fetch profile from repository (network + cache)
            let user = try await profileCachingRepository.fetchProfile()

            // Update app state with loaded data
            appState.profile.dispatch { state in
                state.userModel = .loaded(value: user)
            }
        } catch {
            // Update app state with error
            appState.profile.dispatch { state in
                state.userModel = .failed(error: error)
            }
            throw error
        }
    }

    /// Fetches profile from local cache only (offline mode)
    /// Uses LocalRepository for fast cache-only access
    func fetchProfileFromCache() async throws {
        // Set loading state
        appState.profile.dispatch { state in
            state.userModel.setIsLoading()
        }

        do {
            // Fetch profile from local repository only (synchronous method wrapped in async context)
            let user = try await Task { try profileLocalRepository.fetchProfile() }.value

            // Update app state with loaded data
            appState.profile.dispatch { state in
                state.userModel = .loaded(value: user)
            }
        } catch {
            // Update app state with error
            appState.profile.dispatch { state in
                state.userModel.cancelLoading()
            }
            throw error
        }
    }
}
