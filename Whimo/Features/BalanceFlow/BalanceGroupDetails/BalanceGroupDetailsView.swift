//
//  BalanceGroupDetailsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 22.08.2025.
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

private typealias Module = BalanceGroupDetailsModule
private typealias ModuleView = Module.MainView

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private let titleOverride: String?
        private var navBarOverride: Bool { titleOverride != nil }

        // MARK: - Init
        init(
            titleOverride: String?,
            model: CommodityGroupModel
        ) {
            self.titleOverride = titleOverride
            self._viewModel = .init(wrappedValue: ViewModel(model: model))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: titleOverride ?? viewModel.model.name,
                    titlePrefferedFontStyle: navBarOverride ? .h2 : .h1,
                    trailingItem: navBarOverride ? .notifications : nil
                )
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        Module.CommoditiesList(commodityGroup: viewModel.model)
    }
}

// MARK: - Private Methods
private extension ModuleView {
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceGroupDetailsModule.assemble(model: .init(
            id: "preview",
            name: "Preview Group",
            commodities: []
        ))
    }
}
#endif
