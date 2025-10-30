//
//  AppTabBar+TabBarView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 02.05.2025.
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
import Utility
private typealias CurrentView = AppTabBar.TabBarView

// MARK: - TabBarView
extension AppTabBar {
    public struct TabBarView<Model: DomainModel>: View {
        typealias Constants = AppTabBar.Constants

        // MARK: - Properties
        var tabs: [Model]
        @Binding var selectedTab: Model
        var tabData: (Model) -> TabData

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        public init(
            tabs: [Model],
            selectedTab: Binding<Model>,
            tabData: @escaping (Model) -> TabData
        ) {
            self.tabs = tabs
            self._selectedTab = .init(projectedValue: selectedTab)
            self.tabData = tabData
        }

        // MARK: - Body
        public var body: some View {
            content()
                .background(Constants.backgroundColor)
        }
    }
}

// MARK: - Private Layout
private extension CurrentView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            DefaultDivider()
                .frame(height: 1)
            VStack(spacing: .zero) {
                Spacer()
                    .frame(height: 12)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    ForEach(tabs, id: \.id) { tab in
                        tabView(item: tab)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: Constants.tabBarHeight)
        }
    }

    @ViewBuilder func tabView(item: Model) -> some View {
        AppTabBar.TabView(data: tabData(item)) {
            self.tabViewAction(item)
        }
        .foregroundColor(self.buildItemColor(from: item))
    }
}

// MARK: - Private Methods
private extension CurrentView {
    func buildItemImage(from item: Model) -> UIImage {
        let data = tabData(item)
        return data.image
    }

    func buildItemColor(from item: Model) -> Color {
        self.selectedTab == item ? Constants.selectedTabColor : Constants.normalTabColor
    }

    func tabViewAction(_ item: Model) {
        self.selectedTab = item
    }
}

// MARK: - Previews
#if !RELEASE
import Resources
struct GenericAppTabBarView_Previews: PreviewProvider {
    struct TestTabKeys: DomainModel {
        let title: String
        let image: UIImage

        public var id: Self { self }

        static let home: Self = .init(
            title: "Home",
            image: AppAssets.TabBar.tabbarHome.image
        )
        static let balance: Self = .init(
            title: "Balance",
            image: AppAssets.TabBar.tabbarBalance.image
        )
        static let settings: Self = .init(
            title: "Setings",
            image: AppAssets.TabBar.tabbarSettings.image
        )

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.title == rhs.title &&
            lhs.image == rhs.image
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(image)
        }
    }

    struct Container: View {
        var tabs: [TestTabKeys]
        @State var selectedTab: TestTabKeys = .home

        var body: some View {
            VStack(spacing: 30) {
                CurrentView(
                    tabs: tabs,
                    selectedTab: $selectedTab,
                    tabData: { tab in (tab.title, tab.image) }
                )
            }
        }
    }

    static private let mainTabs: [TestTabKeys] = [
        .home,
        .balance,
        .settings
    ]

    static var previews: some View {
        VStack(spacing: 24) {
            Container(tabs: mainTabs)
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.4))
    }
}
#endif
