//
//  CreateTransactionForm+FileRowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 11.06.2025.
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

private typealias Module = CreateTransactionFormModule
private typealias FileRowView = Module.FileRowView

// MARK: - FileRowView
extension Module {
    struct FileRowView: View {
        // MARK: - Properties
        let file: FileObject

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Gray.gray5.colorSwiftUI)
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Private Layout
private extension FileRowView {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 8) {
            leadingAccessory()
            titleView()
            Spacer()
        }
        .padding(8)
    }

    @ViewBuilder func leadingAccessory() -> some View {
        AppAssets.FarmGeodata.farmGeoFolder.imageSwiftUI
            .frame(width: 24, height: 24)
    }

    @ViewBuilder func titleView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(file.id)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                Text(file.formattedSize())
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CreateTransactionFormFileRowView_Previews: PreviewProvider {
    private static let item: FileObject = .init(
        id: "geojson_example.geojson",
        url: .init(filePath: "path/to/file"),
        creationDate: .now,
        fileType: .typeRegular,
        size: .init(value: 800),
        childs: []
    )

    static var previews: some View {
        VStack {
            FileRowView(file: item)
                .padding()
        }
        .frame(height: UIScreen.main.bounds.height)
    }
}
#endif
