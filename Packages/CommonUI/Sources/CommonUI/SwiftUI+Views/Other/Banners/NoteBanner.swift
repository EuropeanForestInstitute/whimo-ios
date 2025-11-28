//
//  NoteBanner.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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

private typealias Assets = AppAssets.NoteBanner

// MARK: - NoteBanner
public struct NoteBanner: View {
    // MARK: - State
    public enum State {
        case info
        case warning

        var icon: Image {
            switch self {
                case .info:
                    Assets.noteBannerNoteIcon.imageSwiftUI
                case .warning:
                    Assets.noteBannerWarningIcon.imageSwiftUI
            }
        }

        var primaryColor: Color {
            switch self {
                case .info:
                    AppColors.Other.lightBlue.colorSwiftUI
                case .warning:
                    AppColors.Other.lightOrange.colorSwiftUI
            }
        }

        var secondaryColor: Color {
            switch self {
                case .info:
                    AppColors.Primary.primarySeaBlue.colorSwiftUI.opacity(0.1)
                case .warning:
                    AppColors.Expanded.expandedWarning.colorSwiftUI.opacity(0.1)
            }
        }
    }

    // MARK: - ActionButton
    public struct ActionButton {
        let title: String
        let action: () -> Void
    }

    // MARK: - Private Properties
    private let text: String
    private let state: State
    private let actionButton: ActionButton?
    private let closeAction: (() -> Void)?

    // MARK: - Init
    public init(
        text: String,
        state: State = .info,
        actionButton: ActionButton? = nil,
        closeAction: (() -> Void)? = nil
    ) {
        self.text = text
        self.state = state
        self.actionButton = actionButton
        self.closeAction = closeAction
    }

    // MARK: - Body
    public var body: some View {
        content()
            .background { background() }
    }
}

// MARK: - Private Layout
private extension NoteBanner {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 8) {
            state.icon
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    textView()
                    actionButtonView()
                }
                if let closeAction {
                    Button {
                        closeAction()
                    } label: {
                        Assets.noteBannerXMark.imageSwiftUI
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder func textView() -> some View {
        Text(text)
            .appFontRegularSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder func actionButtonView() -> some View {
        if let actionButton {
            Button {
                actionButton.action()
            } label: {
                Text(actionButton.title)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
        }
    }

    @ViewBuilder func background() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(state.primaryColor)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1)
                    .fill(state.secondaryColor)
            }
    }
}

// MARK: - Previews
#if !RELEASE
struct NoteBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NoteBanner(text: "Uploading a file from approved sources (e.g., Open Ground, AgroStack) ensures full traceability.")

            NoteBanner(
                text: "Uploading a file from approved sources (e.g., Open Ground, AgroStack) ensures full traceability.",
                state: .warning
            )
            NoteBanner(
                text: "Uploading a file from approved sources (e.g., Open Ground, AgroStack) ensures full traceability.",
                state: .warning,
                actionButton: .init(
                    title: "View transaction",
                    action: { }
                ),
                closeAction: { }
            )
        }
        .padding()
        .previewDevice(.iPhone15Pro)
    }
}
#endif
