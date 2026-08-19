//
//  Notifications+RowView.swift
//  Whimo
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
import CommonUI
import Resources

private typealias Module = NotificationsModule
private typealias RowView = Module.RowView

// MARK: - MainView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        @Binding var row: RowData

        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

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
private extension RowView {
    @ViewBuilder func content() -> some View {
        HStack(spacing: 8) {
            text()
            Spacer()
            Toggle("", isOn: $row.isEnabled)
                .applyDefaultAppearance()
                .fixedSize()
        }
        .padding()
    }

    @ViewBuilder func text() -> some View {
        VStack(spacing: 4) {
            Group {
                if let subtitle = row.rowType.subtitle {
                    Text(row.rowType.title)
                        .appFontMediumSize16()
                        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                    Text(subtitle)
                        .appFontRegularSize16()
                        .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                } else {
                    Text(row.rowType.title)
                        .appFontRegularSize16()
                        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Previews
#if !RELEASE
struct NotificationsRowView_Previews: PreviewProvider {
    class State: ObservableObject {
        @Published var row1: NotificationsModule.RowData = .init(rowType: .allowNotifications, isEnabled: false)
        @Published var row2: NotificationsModule.RowData = .init(rowType: .transactionPending, isEnabled: true)
    }

    struct Container: View {
        @StateObject var state: State = .init()

        var body: some View {
            VStack {
                RowView(row: $state.row1)
                RowView(row: $state.row2)
            }
        }
    }

    static var previews: some View {
        VStack {
            Container()
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
