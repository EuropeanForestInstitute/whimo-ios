//
//  CoordinatorView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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
import FlowStacks
import enum Resources.AppColors

private typealias Module = CoordinatorModule
private typealias ModuleView = Module.Coordinator

// MARK: - CoordinatorView Protocol
protocol CoordinatorView: View {
    associatedtype Screen
    associatedtype ScreenView: View

    var coordinator: Router<Screen, ScreenView> { get }
}

extension CoordinatorView {
    var body: some View {
        coordinator
    }
}

// MARK: - Coordinator
extension Module {
    struct Coordinator<Screen: AnyScreen, Content: View>: CoordinatorView {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel<Screen>
        @ViewBuilder let buildView: (Screen, Int) -> Content

        // MARK: - Private Properties
        private var navigationPath: Binding<Routes<Screen>> {
            .init(
                get: { viewModel.path },
                set: { viewModel.setNavigationPath($0) }
            )
        }

        // MARK: - Init
        init(navigationHandler: NavigationHandler<Screen>, buildView: @escaping (Screen, Int) -> Content) {
            self._viewModel = .init(wrappedValue: .init(navigationHandler: navigationHandler))
            self.buildView = buildView
        }

        // MARK: - Properties
        var coordinator: Router<Screen, Content> {
            Router(navigationPath, accentColor: AppColors.Primary.primarySeaBlue.colorSwiftUI) { screen, index in
                buildView(screen, index)
            }
        }
    }
}
