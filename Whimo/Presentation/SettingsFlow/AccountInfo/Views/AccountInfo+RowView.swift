//
//  AccountInfo+RowView.swift
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

import SwiftUI
import Resources

private typealias Module = AccountInfoModule
private typealias RowView = Module.RowView
private typealias Assets = AppAssets.AccountInfo

// MARK: - MainView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let row: Row
        let onCopyDidTap: (_ row: Row) -> Void

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        private var showCopyButton: Bool { row.details != nil }

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    AppColors.Other.white.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 8) {
            leadingAccessoryImage()
            text()
            if showCopyButton {
                copyDetailsButton(row: row)
            }
            switch row {
                case .userID:
                    EmptyView()
                case .email, .phone:
                    AppAssets.Shared.sharedChevronRight.imageSwiftUI
            }
        }
        .padding()
    }

    @ViewBuilder func leadingAccessoryImage() -> some View {
        row.leadingAccessory
            .frame(width: 24, height: 24)
    }

    @ViewBuilder func text() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                if let details = row.details {
                    detailsText(details: details)
                } else {
                    noDetailsText()
                }
            }
            .frame(maxWidth: .infinity)
            if !row.isVerified {
                warningLabel()
            }
        }
    }

    @ViewBuilder func detailsText(details: String) -> some View {
        Group {
            Text(details)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .multilineTextAlignment(.leading)
            Text(row.title)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func noDetailsText() -> some View {
        Group {
            Text(row.emptyDetailsMessage)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            Text(row.emptyDetailsTitle)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func warningLabel() -> some View {
        HStack(spacing: 4) {
            AppAssets.AccountInfo.accountInfoWarningIcon.imageSwiftUI
            Text(row.noVerificationMessage)
                .appFontMediumSize14()
                .foregroundStyle(AppColors.Expanded.expandedWarning.colorSwiftUI)
        }
    }

    @ViewBuilder func copyDetailsButton(row: Module.Row) -> some View {
        Button {
            onCopyDidTap(row)
        } label: {
            Assets.accountInfoCopyIcon.imageSwiftUI
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct AccountInfoRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RowView(row: .userID(username: "#155796")) { _ in }
            RowView(row: .email(gadget: .init(identifier: "nxxfvk1234@privaterelay.appleid.com", type: .email, isVerified: true))) { _ in }
            RowView(row: .phone(gadget: .init(identifier: "+237 125 26 23", type: .phone, isVerified: false))) { _ in }
            RowView(row: .phone(gadget: .init(identifier: "+237 125 26 23", type: .phone, isVerified: true))) { _ in }
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
