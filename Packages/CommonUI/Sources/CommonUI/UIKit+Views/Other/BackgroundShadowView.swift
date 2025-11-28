//
//  BackgroundShadowView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 29.04.2025.
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
import func Utility.build

// MARK: - BackgroundShadowView
public struct BackgroundShadowView: UIViewRepresentable {
    // MARK: - Style
    public struct Style {
        public static let card: Self = .init(
            backgroundColor: .white,
            cornerRadius: 8,
            shadowColor: .black.withAlphaComponent(0.1),
            shadowOffset: CGSize(width: 0, height: 1),
            shadowRadius: 2,
            shadowOpacity: 1
        )

        public let backgroundColor: UIColor
        public let cornerRadius: CGFloat
        public let shadowColor: UIColor
        public let shadowOffset: CGSize
        public let shadowRadius: CGFloat
        public let shadowOpacity: Float
    }

    // MARK: - Public Properties
    public let style: Style

    // MARK: - Public Init
    public init(style: Style) {
        self.style = style
    }

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UIView {
        build {
            $0.backgroundColor = style.backgroundColor
            $0.layer.cornerRadius = style.cornerRadius

            $0.layer.shadowColor = style.shadowColor.cgColor
            $0.layer.shadowOffset = style.shadowOffset
            $0.layer.shadowRadius = style.shadowRadius
            $0.layer.shadowOpacity = style.shadowOpacity
            $0.layer.masksToBounds = false
        }
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        uiView.backgroundColor = style.backgroundColor
        uiView.layer.cornerRadius = style.cornerRadius

        uiView.layer.shadowColor = style.shadowColor.cgColor
        uiView.layer.shadowOffset = style.shadowOffset
        uiView.layer.shadowRadius = style.shadowRadius
        uiView.layer.shadowOpacity = style.shadowOpacity
        uiView.layer.masksToBounds = false
    }
}
