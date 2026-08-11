//
//  DownloadTxDetailsView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.09.2025.
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
import Utility
import UniformTypeIdentifiers

private typealias Module = DownloadTxDetailsModule
private typealias ModuleView = Module.MainView

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel
        @EnvironmentObject var navigator: AppFlowNavigator

        // MARK: - Private Properties
        private var showExporter: Binding<Bool> {
            .init {
                switch viewModel.showExporter {
                    case .showZipExporter:
                        return true
                    case .showCsvExporter:
                        return true
                    default:
                        return false
                }
            } set: { newValue in
                if !newValue {
                    viewModel.showExporter = nil
                }
            }
        }
        private var exportedDocument: URLDocument? { viewModel.showExporter?.document }
        private var exportedContentType: UTType { viewModel.showExporter?.contentTypes.first ?? .plainText }
        private var exporterDefaultFilename: String { viewModel.showExporter?.defaultFilename ?? "" }

        // MARK: - Init
        init(transactionId: String, tradersCount: Int) {
            self._viewModel = .init(wrappedValue: .init(
                transactionId: transactionId,
                tradersCount: tradersCount
            ))
        }

        // MARK: - Body
        var body: some View {
            content()
                .fileExporter(
                    isPresented: showExporter,
                    document: exportedDocument,
                    contentType: exportedContentType,
                    defaultFilename: exporterDefaultFilename
                ) { result in
                    switch result {
                        case .success(let success):
                            log.debug("success: \(success)")
                            close()
                        case .failure(let error):
                            log.error("error: \(error)")
                    }
                }
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: .zero) {
            DefaultDivider()
            ForEach(viewModel.options) { option in
                Button {
                    didTapDownloadOption(option)
                } label: {
                    rowView(option: option)
                }
                DefaultDivider()
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    @ViewBuilder func rowView(option: Module.DownloadOption) -> some View {
        VStack(spacing: .zero) {
            HStack(spacing: 8) {
                Image(uiImage: option.image)
                    .frame(width: 24, height: 24)
                Text(option.title)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapDownloadOption(_ option: Module.DownloadOption) {
        switch option {
            case .details:
                viewModel.showDownloadTxDetailsAlert()
            case .farmGeolocation:
                viewModel.showDownloadZipAlert()
        }
    }

    func close() {
        navigator.dismiss()
    }
}

// MARK: - Previews
#if !RELEASE
struct DownloadTxDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DownloadTxDetailsModule.assemble(transactionId: "123", tradersCount: 1)
        }
        .background {
            Color.red
        }
    }
}
#endif
