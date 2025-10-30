//
//  ChangeLanguageView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 30.04.2025.
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
import CommonUI

private typealias Module = ChangeLanguageModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.ChangeLanguage

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Properties
        let showBackButton: Bool

        // MARK: - Private Properties
        private var selectedLanguage: Binding<Module.Model> {
            .init {
                viewModel.selectedLanguage
            } set: { newValue in
                viewModel.didTapChange(language: newValue)
            }
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(
                    title: Localization.title,
                    titlePrefferedFontStyle: .h3,
                    showBackButton: showBackButton
                )
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        list()
            .padding(.bottom, 16)
    }

    @ViewBuilder func list() -> some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.languages) { model in
                rowView(model: model)
            }
        }
    }

    @ViewBuilder private func rowView(model: Module.Model) -> some View {
        VStack(spacing: .zero) {
            Module.RowView(model: model, selection: selectedLanguage)
            DefaultDivider()
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
}

// MARK: - Previews
#if !RELEASE
struct ChangeLanguageView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeLanguageModule.assemble()
    }
}
#endif
