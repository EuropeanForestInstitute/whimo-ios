//
//  Register+ChooseVerifyMethodView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.06.2025.
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

private typealias Module = RegisterModule
private typealias ChooseVerifyMethodView = Module.ChooseVerifyMethodView
private typealias Assets = AppAssets.Otp
private typealias Localization = AppLocale.Register.ChooseVerifyMethod

// MARK: - MainView
extension Module {
    struct ChooseVerifyMethodView: View {
        // MARK: - Public Properties
        let didTapEmail: () -> Void
        let didTapPhone: () -> Void

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension ChooseVerifyMethodView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: 32)
            DefaultDivider()
            actionRowView(title: Localization.email, image: Assets.otpMethodEmail.imageSwiftUI, action: didTapEmail)
            DefaultDivider()
            actionRowView(title: Localization.phone, image: Assets.otpMethodPhone.imageSwiftUI, action: didTapPhone)
            DefaultDivider()
            Spacer()
                .frame(height: 16)
        }
    }

    @ViewBuilder func actionRowView(title: String, image: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowView(title: title, image: image) }
    }

    @ViewBuilder func rowView(title: String, image: Image) -> some View {
        HStack(spacing: 8) {
            image
                .frame(width: 24, height: 24)
            Text(title)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Private Methods
private extension ChooseVerifyMethodView {
}

// MARK: - Previews
#if !RELEASE
struct RegisterChooseVerifyMethodView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseVerifyMethodView(didTapEmail: {}, didTapPhone: {})
    }
}
#endif
