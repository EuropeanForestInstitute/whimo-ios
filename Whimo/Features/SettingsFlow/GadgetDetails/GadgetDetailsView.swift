//
//  GadgetDetailsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.08.2025.
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
import Utility

private typealias Module = GadgetDetailsModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.GadgetDetails

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        @FocusState private var keyboardActiveField: KeyboardField?

        private var textFieldType: TextFieldType {
            switch viewModel.newGadget.type {
                case .email:
                    .email
                case .phone:
                    .phone
            }
        }

        private var gadgetId: Binding<String> {
            .init {
                switch viewModel.newGadget.type {
                    case .email:
                        return viewModel.newGadget.identifier
                    case .phone:
                        let identifier = viewModel.newGadget.identifier
                        if identifier.count <= 1 {
                            return identifier
                        } else {
                            return "+\(identifier)"
                        }
                }
            } set: { newValue in
                let gadget = viewModel.newGadget
                viewModel.newGadget = .init(
                    identifier: newValue,
                    type: gadget.type,
                    isVerified: gadget.isVerified
                )
            }
        }

        private var title: String {
            switch textFieldType {
                case .email:
                    Localization.Title.email
                case .phone:
                    Localization.Title.phone
            }
        }

        private var enableOTPButton: Bool {
            switch viewModel.screenMode {
                case .addGadget, .verifyGadget:
                    return !gadgetId.wrappedValue.isEmpty && !viewModel.newGadget.isVerified
                case .editGadget:
                    return !gadgetId.wrappedValue.isEmpty && viewModel.canEditGadget
            }
        }

        private var buttonTitle: String {
            switch viewModel.screenMode {
                case .editGadget:
                    return Localization.Buttons.change
                case .addGadget, .verifyGadget:
                    return Localization.Buttons.verify
            }
        }

        // MARK: - Init
        init(gadgets: NonEmptyArray<UserModel.GadgetModel>) {
            self._viewModel = .init(wrappedValue: .init(gadgets: gadgets))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: title)
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
                otpButton()
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        .scrollDisabled(self.keyboardActiveField == nil)
    }

    @ViewBuilder func subtitle() -> some View {
        Text(Localization.subtitle)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func textField() -> some View {
        switch textFieldType {
            case .email:
                AppTextField(
                    description: textFieldType.description,
                    placeholder: textFieldType.placeholder,
                    leadingAccessory: textFieldType.leadingAccessory,
                    text: gadgetId,
                    state: viewModel.screenMode == .addGadget ? .default :
                           viewModel.screenMode == .editGadget && viewModel.canEditGadget ? .default : .disabled
                )
                .focused($keyboardActiveField, equals: .gadgetId)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
            case .phone:
                AppPhoneNumberTextField(
                    description: textFieldType.description,
                    text: gadgetId,
                    state: viewModel.screenMode == .addGadget ? .default :
                           viewModel.screenMode == .editGadget && viewModel.canEditGadget ? .default : .disabled
                )
                .focused($keyboardActiveField, equals: .gadgetId)
                .textContentType(.telephoneNumber)
                .submitLabel(.done)
        }
    }

    @ViewBuilder func otpButton() -> some View {
        VStack(spacing: 16) {
            AppButton(
                title: buttonTitle,
                isEnabled: enableOTPButton,
                action: didTapSendOTP
            )
            .animation(.snappy(duration: 0.23), value: enableOTPButton)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapSendOTP() {
        Task { await viewModel.didTapVerifyGadget() }
    }
}

// MARK: - Previews
#if !RELEASE
struct GadgetDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        GadgetDetailsModule.assemble(gadgets: NonEmptyArray(.unverified(identifier: "", type: .email)))
    }
}
#endif
