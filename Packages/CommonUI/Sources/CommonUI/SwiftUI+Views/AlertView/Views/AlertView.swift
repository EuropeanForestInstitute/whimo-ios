//
//  AlertView.swift
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

// MARK: - AlertView
public struct AlertView: View {
    typealias AlertModel = AlertManager.AlertModel

    // MARK: - ButtonsAxis
    enum ButtonsAxis {
        case horizontal
        case vertical
    }

    // MARK: - Properties
    let alertModel: AlertModel
    let actionDidTap: () -> Void

    // MARK: - Init
    init(alertModel: AlertModel, actionDidTap: @escaping () -> Void = { }) {
        self.alertModel = alertModel
        self.actionDidTap = actionDidTap
    }

    // MARK: - Body
    public var body: some View {
        content()
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Other.white.colorSwiftUI)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Gray.gray5.colorSwiftUI)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Private Properties
private extension AlertView {
    // MARK: - Content
    @ViewBuilder func content() -> some View {
        VStack(spacing: 2) {
            Group {
                titleView()
                subtitleView(subtitle: alertModel.subtitle)
                alertContentView(alertModel.contentView)
                buttonsView(alertModel.buttons)
            }
            .background(AppColors.Other.white.colorSwiftUI)
        }
    }

    // MARK: - Text
    @ViewBuilder func titleView() -> some View {
        HStack {
            Text(alertModel.title)
                .appFontMediumSize18()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Spacer()
            Button {
                didTapClose()
            } label: {
                AppAssets.Alert.alertXMark.imageSwiftUI
            }
        }
        .padding(16)
    }

    @ViewBuilder func subtitleView(subtitle: String?) -> some View {
        if let subtitle = alertModel.subtitle {
            Text(subtitle)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
    }

    @ViewBuilder func alertContentView(_ contentView: AnyView?) -> some View {
        if let contentView = contentView {
            VStack {
                contentView
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Buttons
    @ViewBuilder func buttonsStack<V: View>(@ViewBuilder content: () -> V) -> some View {
        switch alertModel.buttonsAxis {
            case .horizontal:
                HStack(spacing: 12) {
                    content()
                }
            case .vertical:
                VStack(spacing: 12) {
                    content()
                }
        }
    }

    @ViewBuilder func buttonsView(_ buttons: [AlertManager.AlertModel.Button]) -> some View {
        buttonsStack {
            ForEach(buttons) { button in
                AppButton(
                    title: button.title,
                    style: button.style,
                    action: buildButtonAction(button)
                )
            }
        }
        .padding(buttons.isEmpty ? .zero : 16)
    }
}

// MARK: - Private Methods
private extension AlertView {
    func didTapClose() {
        actionDidTap()
    }

    func buildButtonAction(_ button: AlertManager.AlertModel.Button) -> () -> Void {
        let action = {
            button.action?()
            didTapClose()
        }

        return action
    }
}

// swiftlint:disable all
// MARK: - Previews
#if !RELEASE
struct AppAlertView_Previews: PreviewProvider {
    static var contentView1: some View {
        VStack(alignment: .center) {
            Text("SAMPLE TEXT").foregroundStyle(.red)
        }
    }

    static var previews: some View {
        VStack {
            AlertView(
                alertModel: .init(feature: AlertManager.AlertModel.Features.Logout.self, { _ in
                    nil
                })
            )

            AlertView(
                alertModel: .init(feature: AlertManager.AlertModel.Features.SaveTransaction.self, { _ in
                    nil
                })
            )

            AlertView(
                alertModel: .init(feature: AlertManager.AlertModel.Features.DeleteAccount.self, { _ in
                    nil
                })
            )
            AlertView(alertModel: .init(
                title: "Traceability status",
                subtitle: "The pie chart can give you an idea of the traceability performance (by showing the proportion of their suppliers that fall into each traceability status).",
                contentView: .init(contentView1)
            ))
        }
        .padding()
        .background(.red.opacity(0.5))
        .previewDevice(.iPhone15Pro)
    }
}
#endif
// swiftlint:enable all
