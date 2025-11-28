//
//  EmptyStateView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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

// MARK: - EmptyStateView
public struct EmptyStateView: View {
    // MARK: - Properties
    let title: String
    let subtitle: String
    let image: Image

    // MARK: - Init
    public init(
        title: String,
        subtitle: String,
        image: Image = AppAssets.Home.emptyState.imageSwiftUI
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }

    // MARK: - Body
    public var body: some View {
        content()
            .ignoresSafeArea(.keyboard, edges: .all)
    }
}

// MARK: - Private Layout
private extension EmptyStateView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 24) {
            accessoryImage()
            text()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder func accessoryImage() -> some View {
        Circle()
            .fill(AppColors.Gray.gray5.colorSwiftUI)
            .frame(width: 72, height: 72)
            .overlay { image }
    }

    @ViewBuilder func text() -> some View {
        VStack(spacing: 12) {
            Text(title)
                .appFontSemiboldSize22()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Text(subtitle)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            title: "No transactions",
            subtitle: "Once you start buying or selling, your transactions will appear here.\n\nTap the “+” button to record your first one.",
            image: AppAssets.Home.emptyState.imageSwiftUI
        )
    }
}
#endif
