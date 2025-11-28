//
//  LoaderView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 22.05.2025.
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

// MARK: - LoaderView
public struct LoaderView: View {
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                ProgressView()
                    .controlSize(.large)
                    .scaleEffect(0.8)
                    .frame(
                        width: proxy.size.height * 0.1,
                        height: proxy.size.height * 0.1
                    )
                    .background {
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    }
                    .foregroundColor(Color.primary)
                    .cornerRadius(20)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height / 2
                    )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews
#if !RELEASE
struct LoaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LoaderView()
        }
    }
}
#endif
