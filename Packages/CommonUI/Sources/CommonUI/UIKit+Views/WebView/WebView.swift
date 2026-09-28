//
//  WebView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 25.06.2025.
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

// MARK: - WebView
public struct WebView: View {
    // MARK: - Public Properties
    public let stringURL: String

    // MARK: - Private Properties
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    public init(stringURL: String) {
        self.stringURL = stringURL
    }

    // MARK: - Body
    public var body: some View {
        content()
            .ignoresSafeArea(.all, edges: .all)
    }
}

// MARK: - Private Layout
private extension WebView {
    @ViewBuilder func content() -> some View {
        if let url: URL = .init(string: stringURL) {
            if UIApplication.shared.canOpenURL(url) {
                WebViewRepresentable(url: stringURL)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Close")
                                    .appFontRegularSize16()
                                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
                            }
                        }
                    }
            } else {
                Text("Cannot Open")
            }
        } else {
            Text("Wrong URL")
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // swiftlint:disable:next trailing_closure
            WebView(stringURL: "https://google.com")
                .previewDevice(.iPhone15Pro)
        }

        NavigationView {
            // swiftlint:disable:next trailing_closure
            WebView(stringURL: "https://google.com")
                .previewDevice(.iPhoneSE)
        }
    }
}
#endif
