//
//  AppCheckBox.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 08.05.2025.
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

// MARK: - AppCheckBox
public struct AppCheckBox: View {
    // MARK: - Properties
    @Binding var isSelected: Bool

    // MARK: - Private Properties
    private var backgroundColor: Color {
        isSelected
        ? AppColors.Primary.primarySeaBlue.colorSwiftUI
        : AppColors.Other.white.colorSwiftUI
    }

    // MARK: - Public Init
    public init(isSelected: Binding<Bool>) {
        self._isSelected = isSelected
    }

    // MARK: - Body
    public var body: some View {
        content()
    }
}

// MARK: - Private Layout
private extension AppCheckBox {
    @ViewBuilder func content() -> some View {
        Button {
            isSelected.toggle()
        } label: {
            rectangle()
        }
    }

    @ViewBuilder func rectangle() -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
            .frame(width: 24, height: 24)
            .overlay(content: overlay)
    }

    @ViewBuilder func overlay() -> some View {
        if isSelected {
            AppAssets.Checkbox.checkboxAgreeIcon.imageSwiftUI
        } else {
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.Gray.gray10.colorSwiftUI, lineWidth: 1)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct AppCheckBox_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AppCheckBox(isSelected: .constant(false))
            AppCheckBox(isSelected: .constant(true))
        }
        .previewDevice(.iPhone15Pro)
    }
}
#endif
