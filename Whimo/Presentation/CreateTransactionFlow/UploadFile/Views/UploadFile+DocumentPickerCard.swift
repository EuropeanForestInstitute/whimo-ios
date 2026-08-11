//
//  UploadFile+DocumentPickerCard.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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

private typealias Module = UploadFileModule
private typealias InfoCard = Module.DocumentPickerCard
private typealias Localization = AppLocale.UploadFile.InfoCard
private typealias Assets = AppAssets.FarmGeodata

// MARK: - MainView
extension Module {
    struct DocumentPickerCard: View {
        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        // MARK: - Body
        var body: some View {
            content()
                .dashedBackground()
        }
    }
}

// MARK: - Private Layout
private extension InfoCard {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 16) {
            accessoryImage()
            text()
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder func accessoryImage() -> some View {
        Circle()
            .fill(AppColors.Other.lightBlue.colorSwiftUI)
            .frame(width: 48, height: 48)
            .overlay { Assets.farmGeoShareIcon.imageSwiftUI }
    }

    @ViewBuilder func text() -> some View {
        VStack(spacing: 8) {
            Text(Localization.title)
                .appFontMediumSize18()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Text(Localization.subtitle)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews
#if !RELEASE
struct UploadFileDocumentPickerCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InfoCard()
                .padding()
        }
        .background(.red.opacity(0.5))
    }
}
#endif
