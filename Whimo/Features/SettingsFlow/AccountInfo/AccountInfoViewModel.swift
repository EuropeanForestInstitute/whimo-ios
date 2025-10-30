//
//  AccountInfoViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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
import UIKit
import Utility
import enum Resources.AppLocale

private typealias Module = AccountInfoModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published private(set) var userProfile: UserProfile = .empty

        var rows: [Row] {
            [
                .userID(username: "#\(userProfile.username)"),
                .email(gadget: userProfile.email),
                .phone(gadget: userProfile.phone)
            ]
        }

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.profileService) private var profileService

        // MARK: - Init
        init() {
            setupBinding()
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapCopy(row: AccountInfoModule.Row) {
            typealias Localization = AppLocale.AccountInfo.Toast

            guard let copyText = row.details else { return }

            UIPasteboard.general.string = copyText
            let message: String
            switch row {
                case .userID:
                    message = Localization.Copied.id
                case .email:
                    message = Localization.Copied.email
                case .phone:
                    message = Localization.Copied.phone
            }
            appState.showInfo(message: message)
        }

        func didTapProfileRow(_ rowType: Row) {
            let currentUser = appState.profile[\.userModel].value ?? .empty
            let allGadgets = currentUser.gadgets

            let gadgetsToPass: NonEmptyArray<UserModel.GadgetModel>
            switch rowType {
                case .userID:
                    return
                case .email(let eGadget):
                    let emailGadget = eGadget ?? .unverified(identifier: "", type: .email)
                    gadgetsToPass = NonEmptyArray(emailGadget, allGadgets.filter { $0.type != .email })
                case .phone(let pGadget):
                    let phoneGadget = pGadget ?? .unverified(identifier: "", type: .phone)
                    gadgetsToPass = NonEmptyArray(phoneGadget, allGadgets.filter { $0.type != .phone })
            }

            let screen: Screen = .gadgetDetails(gadgets: gadgetsToPass)
            appState.navigation[\.path].append(.push(screen))
        }

        func didPullRefresh() async {
            let refreshTask = Task { [weak self] in
                guard let self else { return }

                await self.fetchUserDataRequest()
            }

            _ = await refreshTask.result
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func setupBinding() {
        appState.profile.state
            .map(\.userModel)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }

                switch user {
                    case .notRequested, .requested:
                        break
                    case .isLoading(let lastValue):
                        if let lastValue {
                            self.userProfile = .init(from: lastValue)
                        }
                    case .loaded(let value):
                        self.userProfile = .init(from: value)
                    case .failed(let error):
                        self.appState.showError(message: error.localizedDescription)
                }
            }
            .store(in: cancellable)
    }

    func startup() {
        Task { [weak self] in
            self?.appState.system[\.isLoading] = true
            defer { self?.appState.system[\.isLoading] = false }

            await self?.fetchUserDataRequest()
        }
    }

    // MARK: - Common
    func fetchUserDataRequest() async {
        try? await profileService.fetchProfile()
    }
}
