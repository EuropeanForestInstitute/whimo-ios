//
//  TabBarView.swift
//  Whimo
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
import CommonUI
import var Utility.log

private typealias Module = TabBarModule
private typealias ModuleView = Module.MainView

private enum Constants {
    static let kBottomPaddingValue: CGFloat = AppTabBar.Constants.tabBarHeight
}

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Privatete Properties
        private var selectedTab: Binding<TabBarKeys> {
            .init {
                viewModel.selectedTab
            } set: { newValue in
                viewModel.setSelectedTab(newValue)
            }
        }

        // MARK: - Init
        init() {
            initTabBarAppearance()
        }

        // MARK: - Body
        var body: some View {
            content()
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard, edges: .all)
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        ZStack {
            tabBarContent()
            tabBarView()
        }
    }

    @ViewBuilder func tabBarContent() -> some View {
        VStack(spacing: .zero) {
            TabView(selection: selectedTab.id) {
                tabs()
            }
            Rectangle()
                .fill(.clear)
                .frame(height: Constants.kBottomPaddingValue)
                .ignoresSafeArea(.keyboard, edges: .all)
        }
    }

    @ViewBuilder func tabBarView() -> some View {
        VStack {
            Spacer()
            AppTabBar.TabBarView(
                tabs: viewModel.defaultTabItems,
                selectedTab: selectedTab,
                tabData: { tab in (tab.title, tab.image) }
            )
        }
    }

    @ViewBuilder func tabs() -> some View {
        ForEach(viewModel.defaultTabItems) { tab in
            Group {
                switch tab {
                    case .home:
                        HomeModule.assemble()
                    case .balance:
                        BalanceMainModule.assemble()
                    case .settings:
                        SettingsModule.assemble()
                    default:
                        EmptyView()
                }
            }
            .tag(tab.id)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func initTabBarAppearance() {
        UITabBar.appearance().isHidden = true
    }

    func buildTabData(tab: TabBarKeys) -> AppTabBar.TabData { (tab.title, tab.image) }
}

// MARK: - Previews
#if !RELEASE
struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarModule.assemble()
    }
}
#endif
