//
//  UploadFileView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.05.2025.
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

private typealias Module = UploadFileModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.UploadFile

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var isConfirmButtonEnabled: Bool {
            viewModel.selectedFile != nil
        }

        // MARK: - Init
        init(mode: Mode) {
            _viewModel = .init(wrappedValue: .init(mode: mode))
        }

        // MARK: - Body
        var body: some View {
            content()
                .applyNavigationBar(title: Localization.title)
                .background {
                    AppColors.Gray.gray5.colorSwiftUI
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    // MARK: - Content
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            uploadFilePage()
        }
        .overlay { bottomToolbar() }
    }

    @ViewBuilder func uploadFilePage() -> some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: 16)
            VStack(spacing: 16) {
                NoteBanner(text: Localization.Note.text)
                    .padding(.horizontal, 16)
                if let selectedFile = viewModel.selectedFile {
                    Module.FileRow(
                        file: selectedFile,
                        onUploadMoreTap: didTapUploadAnotherFile,
                        onDeleteTap: didTapRemoveSelectedFile
                    )
                } else {
                    documentPickerCard()
                        .padding(.horizontal, 16)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder func documentPickerCard() -> some View {
        Button {
            didTapUploadFile()
        } label: {
            Module.DocumentPickerCard()
        }
    }

    // MARK: - Bottom toolbar
    @ViewBuilder func bottomToolbar() -> some View {
        VStack(spacing: 12) {
            Spacer()
            AppButton(
                title: Localization.Buttons.confirm,
                isEnabled: isConfirmButtonEnabled,
                action: didTapConfirm
            )
            .padding(.bottom, 16)
            .animation(.snappy, value: isConfirmButtonEnabled)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapUploadAnotherFile() {
        viewModel.didTapUploadAnotherFile()
    }

    func didTapRemoveSelectedFile() {
        viewModel.didTapRemoveSelectedFile()
    }

    func didTapUploadFile() {
        viewModel.didTapUploadFile()
    }

    func didTapConfirm() {
        viewModel.didTapConfirm()
    }
}

// MARK: - Previews
#if !RELEASE
struct UploadFileView_Previews: PreviewProvider {
    static var previews: some View {
        UploadFileModule.assemble(mode: .filePicker)
    }
}
#endif
