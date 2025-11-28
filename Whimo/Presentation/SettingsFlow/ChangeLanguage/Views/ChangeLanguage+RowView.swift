//
//  ChangeLanguage+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.04.2025.
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

private typealias Module = ChangeLanguageModule
private typealias RowView = Module.RowView

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let model: ChangeLanguageModule.Model
        let selection: Binding<ChangeLanguageModule.Model>

        // MARK: - Private Properties
        private var isSelected: Bool { selection.wrappedValue == model }

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    AppColors.Other.white.colorSwiftUI
                }
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        Button {
            selection.wrappedValue = model
        } label: {
            HStack(spacing: 8) {
                flagImage()
                title()
                trailingAccessory()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder func flagImage() -> some View {
        model.flag
            .frame(width: 24, height: 24)
    }

    @ViewBuilder func title() -> some View {
        Text(model.title)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .frame(height: 18)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func trailingAccessory() -> some View {
        if isSelected {
            AppAssets.Language.langSelectedAccessory.imageSwiftUI
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Private Methods
private extension RowView { }

// MARK: - Previews
#if !RELEASE
struct ChangeLanguageRowView_Previews: PreviewProvider {
    private static let model: ChangeLanguageModule.Model = .init(localize: .english)

    static var previews: some View {
        VStack {
            RowView(model: model, selection: .constant(model))
            RowView(model: model, selection: .constant(.init(localize: .french)))
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
