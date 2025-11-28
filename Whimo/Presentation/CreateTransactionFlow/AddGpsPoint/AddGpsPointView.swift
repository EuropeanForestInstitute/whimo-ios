//
//  AddGpsPointView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import Extensions
import MapKit

private typealias Module = AddGpsPointModule
private typealias ModuleView = Module.MainView
private typealias Localization = AppLocale.AddGpsPoint
private typealias Assets = AppAssets.FarmGeodata

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()
        @EnvironmentObject var navigator: AppFlowNavigator

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
        mapPage()
            .ignoresSafeArea()
            .overlay { bottomToolbar() }
    }

    // MARK: - Pages
    @ViewBuilder func mapPage() -> some View {
        Map(coordinateRegion: $viewModel.selectedRegion)
            .overlay {
                Assets.farmGeoMapPin.imageSwiftUI
                    .frame(width: 60, height: 60)
                    .padding(.bottom, 60)
            }
    }

    @ViewBuilder func mapLabel() -> some View {
        HStack(spacing: 6) {
            Assets.farmGeoMapLabelPin.imageSwiftUI
                .frame(width: 20, height: 20)
            Text(viewModel.selectedRegion.center.formatToDMS())
                .frame(maxWidth: .infinity, alignment: .leading)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.Other.white.colorSwiftUI)
        }
    }

    // MARK: - Bottom toolbar
    @ViewBuilder func bottomToolbar() -> some View {
        VStack(spacing: 12) {
            Spacer()
            mapLabel()
            AppButton(title: Localization.Buttons.confirm, action: didTapConfirm)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Private Methods
private extension ModuleView {
    func didTapConfirm() {
        viewModel.didTapConfirmAddGPS()
    }
}

// MARK: - Previews
#if !RELEASE
struct FarmGeodataView_Previews: PreviewProvider {
    private struct Container: View {
        @StateObject private var viewModel: AddGpsPointModule.ViewModel = .init()

        var body: some View {
            AddGpsPointModule.MainView(viewModel: viewModel)
        }
    }

    static var previews: some View {
        AddGpsPointModule.assemble()
            .previewDisplayName("Empty")

        Container()
            .previewDisplayName("Document selected")
    }
}
#endif
