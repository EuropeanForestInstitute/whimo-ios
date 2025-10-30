//
//  Settings+OfflineInfoView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 21.06.2025.
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

private typealias Module = SettingsModule
private typealias OfflineInfoView = Module.OfflineInfoView
private typealias Assets = AppAssets.Settings
private typealias Localization = AppLocale.Settings.OfflineInfoView

// MARK: - OfflineInfoView
extension Module {
    struct OfflineInfoView: View {
        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Gray.gray10.colorSwiftUI)
                }
        }
    }
}

// MARK: - Private Layout
private extension OfflineInfoView {
    @ViewBuilder func content() -> some View {
        HStack(spacing: 8) {
            Assets.settingsOfflineIcon.imageSwiftUI
            Text(Localization.title)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews
#if !RELEASE
struct SettingsOfflineInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OfflineInfoView()
        }
    }
}
#endif
