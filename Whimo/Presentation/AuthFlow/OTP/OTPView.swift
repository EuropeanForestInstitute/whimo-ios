//
//  OTPView.swift
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
import enum StorageKit.KeychainModels
import Resources
import Utility
import Extensions

private typealias Module = OTPModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.Otp

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var fieldFocus: Int?

        private var subtitleText: AttributedString {
            let identifier: String
            switch viewModel.selectedGadget.type {
                case .email:
                    identifier = viewModel.selectedGadget.identifier
                case .phone:
                    identifier = viewModel.selectedGadget.identifier
            }

            var title: AttributedString = .init(Localization.subtitle(identifier))
            title.replacingOccurrences(
                of: identifier,
                with: .init([
                    .font: AppFonts.FiraSans.medium.font(size: 16),
                    .foregroundColor: AppColors.Gray.gray90.color
                ])
            )

            return title
        }

        private var switchGadgetButtonText: String {
            let text: String
            switch viewModel.selectedGadget.type {
                case .email:
                    text = Localization.Buttons.switchToPhone
                case .phone:
                    text = Localization.Buttons.switchToEmail
            }

            return text
        }

        // MARK: - Init
        init(parrentFlow: ParrentFlow, gadgets: NonEmptyArray<UserModel.GadgetModel>) {
            self._viewModel = .init(wrappedValue: .init(parrentFlow: parrentFlow, gadgets: gadgets))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
                .onAppear {
                    withAnimation(.default.speed(1.25)) {
                        fieldFocus = 0
                    }
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 32) {
            subtitle()
            OTPField(lenght: 6, otp: $viewModel.otp)
                .focused($fieldFocus, equals: 0)
                .allowsHitTesting(false)
            VStack(spacing: 16) {
                AppButton(
                    title: Localization.Buttons.confirm,
                    isEnabled: viewModel.enableConfirmButton,
                    action: didTapConfirm
                )
                .animation(.snappy(duration: 0.23), value: viewModel.enableConfirmButton)
                resendCode()
            }
            Spacer()
            if viewModel.showChangeVerifyMethodButton {
                switchGadgetButton()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    // MARK: - Header
    @ViewBuilder func subtitle() -> some View {
        Text(subtitleText)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Buttons
    @ViewBuilder func resendCode() -> some View {
        HStack(spacing: 4) {
            Text(Localization.ResendCode.title)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Button {
                didTapResendCode()
            } label: {
                Text(Localization.ResendCode.button)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
        }
    }

    @ViewBuilder func switchGadgetButton() -> some View {
        Button {
            didTapSwitchGadget()
        } label: {
            Text(Localization.Buttons.switchToPhone)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapConfirm() {
        Task { await viewModel.didTapConfirm() }
    }

    func didTapResendCode() {
        Task { await viewModel.didTapResendCode() }
    }

    func didTapSwitchGadget() {
        Task { await viewModel.didTapSwitchGadget() }
    }
}

// MARK: - Previews
#if !RELEASE
struct OTPView_Previews: PreviewProvider {
    static var previews: some View {
        OTPModule.assemble(
            parrentFlow: .singUp(credentials: .init(
                email: "john@example.com",
                phone: "1234567890",
                password: "123",
                repeatPassword: "123",
                isTermsAccepted: true
            )),
            gadgets: NonEmptyArray(
                .init(
                    identifier: "john@example.com",
                    type: .email,
                    isVerified: true
                ),
                [
                    .init(
                        identifier: "1234567890",
                        type: .phone,
                        isVerified: false
                    )
                ]
            ))
    }
}
#endif
