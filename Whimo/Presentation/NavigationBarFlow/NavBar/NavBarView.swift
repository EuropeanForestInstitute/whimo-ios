//
//  NavBarView.swift
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

private typealias Module = NavBarModule
private typealias ModuleView = Module.MainView

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Properties
        let title: String
        let titlePrefferedFontStyle: TitleFontStyle
        let trailingItem: TrailingItem?
        let showBackButton: Bool

        // MARK: - Private Properties
        private var needsToShowBackButton: Bool {
            showBackButton && viewModel.screensCount > 1
        }

        private var titleFont: Font {
            needsToShowBackButton ? TitleFontStyle.h3.font : titlePrefferedFontStyle.font
        }

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
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        HStack(spacing: 8) {
            if needsToShowBackButton {
                backButton()
            }
            titleView()
            Spacer()
            if let trailingItem {
                trailingItemView(trailingItem)
            }
        }
        .padding(.all, 16)
    }

    @ViewBuilder func backButton() -> some View {
        Button {
            didTapBackButton()
        } label: {
            AppAssets.Navigation.navigationArrowLeft.imageSwiftUI
        }
    }

    @ViewBuilder func titleView() -> some View {
        Text(title)
            .font(titleFont)
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            .frame(height: 28)
    }

    @ViewBuilder func trailingItemView(_ trailingItem: Module.TrailingItem) -> some View {
        Button {
            switch trailingItem {
                case .notifications, .more:
                    didTapTrailingItem(trailingItem)
                case .custom(_, _, let action):
                    action()
            }
        } label: {
            Image(uiImage: getTrailingImage(from: trailingItem))
                .frame(width: 24, height: 24)
                .animation(.snappy, value: trailingItem.alternativeImage)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    // MARK: - Common
    func getTrailingImage(from trailingItem: Module.TrailingItem) -> UIImage {
        let uiImage: UIImage
        switch trailingItem {
            case .notifications:
                let dynamicImage = viewModel.showNotificationsBadge ? trailingItem.alternativeImage ?? trailingItem.image : trailingItem.image
                uiImage = dynamicImage
            case .more:
                uiImage = trailingItem.image
            case .custom(let image, _, _):
                uiImage = image
        }

        return uiImage
    }

    // MARK: - Actions
    func didTapBackButton() {
        navigator.goBack()
    }

    func didTapTrailingItem(_ item: Module.TrailingItem) {
        switch item {
            case .notifications:
                navigator.push(.notificationsList)
            case .more:
                navigator.presentSheet(.more)
            case .custom:
                return
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct NavBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NavBarModule.assemble(
                title: "Settings",
                titlePrefferedFontStyle: .h1
            )
            Spacer()
        }
        .background(.red.opacity(0.5))
        .previewDisplayName("h1")

        VStack {
            NavBarModule.assemble(
                title: "Settings",
                titlePrefferedFontStyle: .h2
            )
            Spacer()
        }
        .background(.red.opacity(0.5))
        .previewDisplayName("h2")

        VStack {
            NavBarModule.assemble(
                title: "Settings",
                titlePrefferedFontStyle: .h2,
                trailingItem: .more
            )
            Spacer()
        }
        .background(.red.opacity(0.5))
        .previewDisplayName("Settings h2 + trailing item")

        VStack {
            NavBarModule.assemble(
                title: "Transactions",
                titlePrefferedFontStyle: .h2,
                trailingItem: .notifications
            )
            Spacer()
        }
        .background(.red.opacity(0.5))
        .previewDisplayName("Transactions h2 + trailing item")

        VStack {
            NavBarModule.assemble(
                title: "Settings",
                titlePrefferedFontStyle: .h3
            )
            Spacer()
        }
        .background(.red.opacity(0.5))
        .previewDisplayName("h3")
    }
}
#endif
