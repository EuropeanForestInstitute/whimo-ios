//
//  AlertOverlayView.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 09.05.2025.
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
import IdentifiedCollections

// MARK: - AlertOverlayView
struct AlertOverlayView: View {
    // MARK: - Tuple
    private struct Tuple: Equatable {
        var count: Int
        var isAppeared: Bool
    }

    // MARK: - Properties
    @ObservedObject var manager: AlertManager

    // MARK: - Private Properties
    private var models: IdentifiedArrayOf<AlertManager.AlertModel> { manager.isAppeared ? manager.models : [] }

    // MARK: - Body
    var body: some View {
        content()
            .onAppear(perform: manager.onAppear)
    }
}

// MARK: - Private Layout
private extension AlertOverlayView {
    @ViewBuilder func content() -> some View {
        VStack {
            ZStack {
                ForEach(models) { alert in
                    alertOverlay(alert: alert, actionDidTap: didTapAnyAction)
                }
            }
            .background {
                background()
                    .animation(
                        nil,
                        value: Tuple(count: manager.models.count, isAppeared: manager.isAppeared)
                    )
                    .onTapGesture {
                        manager.close()
                    }
            }
        }
        .animation(
            .spring(duration: AlertManager.Settings.removalAnimationDuration),
            value: Tuple(count: manager.models.count, isAppeared: manager.isAppeared)
        )
    }

    @ViewBuilder func background() -> some View {
        AppColors.Primary.primaryMidnightBlue.colorSwiftUI
            .opacity(0.3)
            .ignoresSafeArea()
    }

    @ViewBuilder func alertOverlay(alert: AlertManager.AlertModel, actionDidTap: @escaping () -> Void) -> some View {
        VStack {
            Spacer()
            AlertView(alertModel: alert, actionDidTap: actionDidTap)
                .padding(16)
            Spacer()
        }
        .transition(.asymmetric(
            insertion: .transform(
                opacity: 0.0,
                scale: 0.5
            ),
            removal: .transform(opacity: 0)
        ))
    }
}

// MARK: - Private Methods
private extension AlertOverlayView {
    func didTapAnyAction() {
        manager.close()
    }
}

// MARK: - Previews
#if !RELEASE
struct AppAlertOverlayView_Previews: PreviewProvider {
    struct Container: View {
        @StateObject var manager: AlertManager = .init()

        init(manager: AlertManager) {
            self._manager = .init(wrappedValue: manager)

            manager.show(feature: AlertManager.AlertModel.Features.Logout.self) { _ in nil }
        }

        var body: some View {
            AlertOverlayView(manager: manager)
        }
    }

    static var previews: some View {
        VStack {
            Container(manager: .init())
        }
        .previewDevice(.iPhone15Pro)
    }
}
#endif
