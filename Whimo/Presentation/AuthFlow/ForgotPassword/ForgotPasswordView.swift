//
//  ForgotPasswordView.swift
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

private typealias Module = ForgotPasswordModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.ForgotPassword

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
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                subtitle()
                textField()
                forgotPasswordButtons()
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

    // MARK: - Buttons
    @ViewBuilder func textField() -> some View {
        switch viewModel.textFieldType {
            case .email:
                AppTextField(
                    description: viewModel.textFieldType.description,
                    placeholder: viewModel.textFieldType.placeholder,
                    leadingAccessory: viewModel.textFieldType.leadingAccessory,
                    text: $viewModel.gadgetIdentifier
                )
                .focused($keyboardActiveField, equals: .username)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
            case .phone:
                AppPhoneNumberTextField(
                    description: viewModel.textFieldType.description,
                    text: $viewModel.gadgetIdentifier
                )
                .focused($keyboardActiveField, equals: .username)
                .textContentType(.telephoneNumber)
                .submitLabel(.done)
        }
    }

    @ViewBuilder func switchFieldButton() -> some View {
        Button {
            didTapToggleTextField()
        } label: {
            Text(Localization.Buttons.switchToPhone)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        }
    }

    @ViewBuilder func forgotPasswordButtons() -> some View {
        VStack(spacing: 16) {
            AppButton(
                title: Localization.Buttons.sendCode,
                isEnabled: viewModel.enableSendCodeButton,
                action: didTapSendCode
            )
            .animation(.snappy(duration: 0.23), value: viewModel.enableSendCodeButton)
            switchFieldButton()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapToggleTextField() {
        viewModel.didTapToggleTextField()
    }

    func didTapSendCode() {
        Task { await viewModel.didTapSendCode() }
    }
}

// MARK: - Previews
#if !RELEASE
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordModule.assemble()
    }
}
#endif
