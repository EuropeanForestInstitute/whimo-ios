//
//  UploadFileFile+Row.swift
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
private typealias FileRow = Module.FileRow
private typealias Assets = AppAssets.FarmGeodata
private typealias Localization = AppLocale.UploadFile.FileRow

// MARK: - FileRow
extension Module {
    struct FileRow: View {
        // MARK: - Public Properties
        let file: FileObject
        let onUploadMoreTap: () -> Void
        let onDeleteTap: () -> Void

        // MARK: - Body
        var body: some View {
            content()
                .background(AppColors.Other.white.colorSwiftUI)
        }
    }
}

// MARK: - Private Methods
private extension FileRow {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 8) {
            leadingAccessory()
            titleView()
            Spacer()
            deleteButton()
        }
        .padding(16)
    }

    @ViewBuilder func leadingAccessory() -> some View {
        Assets.farmGeoFolder.imageSwiftUI
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
            uploadFileButton()
        }
    }

    @ViewBuilder func uploadFileButton() -> some View {
        Button {
            onUploadMoreTap()
        } label: {
            Text(Localization.button)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        }
    }

    @ViewBuilder func deleteButton() -> some View {
        Button {
            onDeleteTap()
        } label: {
            Assets.farmGeoTrash.imageSwiftUI
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct UploadFileFileRow_Previews: PreviewProvider {
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
            FileRow(
                file: item,
                onUploadMoreTap: { },
                onDeleteTap: { }
            )
        }
        .frame(height: UIScreen.main.bounds.height)
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.5))
    }
}
#endif
