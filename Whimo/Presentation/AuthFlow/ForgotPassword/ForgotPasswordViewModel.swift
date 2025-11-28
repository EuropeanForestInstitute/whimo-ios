//
//  ForgotPasswordViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 01.05.2025.
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
import enum Resources.LocalizeKeys
import StorageKit
import Utility

private typealias Module = ForgotPasswordModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        // MARK: - Public Properties
        @Published var gadgetIdentifier = ""
        @Published var textFieldType: TextFieldType = .email

        var enableSendCodeButton: Bool { !gadgetIdentifier.isEmpty }

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState

        // MARK: - Init
        init() { }

        // MARK: - ViewModelProtocol
        func didTapToggleTextField() {
            textFieldType.toggle()
            gadgetIdentifier = ""
        }

        func didTapSendCode() async {
            let gadget = prepareGadget(gadgetIdentifier: gadgetIdentifier)
            let screen: Screen = .otp(parrentFlow: .restorePassword, gadgets: NonEmptyArray(gadget))
            appState.navigation[\.path].append(.push(screen))
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    func prepareGadget(gadgetIdentifier: String) -> UserModel.GadgetModel {
        switch textFieldType {
            case .email:
                return .unverified(identifier: gadgetIdentifier, type: .email)
            case .phone:
                return .unverified(identifier: gadgetIdentifier, type: .phone)
        }
    }
}
