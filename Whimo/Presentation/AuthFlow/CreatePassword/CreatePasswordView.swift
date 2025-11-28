//
//  CreatePasswordView.swift
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
import CommonUI
import Resources

private typealias Module = CreatePasswordModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.CreatePassword

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
                .keyboardDefaultToolbar(action: self.keyboardActiveField = .none)
//                .localizableView()
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                subtitle()
                passwordForm()
                confirmButton()
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        .scrollDisabled(self.keyboardActiveField == nil)
    }

    // MARK: - Header
    @ViewBuilder func subtitle() -> some View {
        Text(Localization.subtitle)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Text Fields
    @ViewBuilder func passwordForm() -> some View {
        VStack(spacing: 16) {
            AppTextField(
                description: Localization.TextFields.Password.description,
                placeholder: Localization.TextFields.Password.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                text: $viewModel.password,
                tapDestination: .textField(keyboardActiveField = .password)
            )
            .focused($keyboardActiveField, equals: .password)
            .textContentType(.newPassword)
            .submitLabel(.next)
            AppTextField(
                description: Localization.TextFields.ConfirmPassword.description,
                placeholder: Localization.TextFields.ConfirmPassword.placeholder,
                leadingAccessory: AppAssets.Shared.sharedPasswordIcon.imageSwiftUI,
                trailingItem: .secureText,
                text: $viewModel.repeatPassword,
                tapDestination: .textField(keyboardActiveField = .confirmPassword)
            )
            .focused($keyboardActiveField, equals: .confirmPassword)
            .textContentType(.password)
            .submitLabel(.done)
        }
        .onSubmit(focusNextField)
    }

    // MARK: - Buttons
    @ViewBuilder func confirmButton() -> some View {
        AppButton(
            title: Localization.Buttons.confirm,
            isEnabled: viewModel.enableConfirmButton,
            action: didTapConfirm
        )
        .animation(.snappy(duration: 0.23), value: viewModel.enableConfirmButton)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func focusNextField() {
        switch keyboardActiveField {
            case .password:
                keyboardActiveField = .confirmPassword
            case .confirmPassword:
                keyboardActiveField = .none
            case .none:
                break
        }
    }

    func didTapConfirm() {
        Task { await viewModel.didTapChangePassword() }
    }
}

// MARK: - Previews
#if !RELEASE
struct CreatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordModule.assemble()
    }
}
#endif
