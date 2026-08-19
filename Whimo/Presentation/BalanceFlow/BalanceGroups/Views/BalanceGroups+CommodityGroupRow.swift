//
//  BalanceGroups+CommodityGroupRow.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 15.08.2025.
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

private typealias Module = BalanceGroupsModule
private typealias CommodityGroupRow = Module.CommodityGroupRow

// MARK: - RowItemsList
extension Module {
    struct CommodityGroupRow: View {
        // MARK: - Properties
        let model: CommodityGroupModel

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    AppColors.Other.white.colorSwiftUI
                }
        }
    }
}

// MARK: - Private Layout
private extension CommodityGroupRow {
    @ViewBuilder func content() -> some View {
        HStack {
            label()
            trailingAccessoryImage()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }

    @ViewBuilder func label() -> some View {
        HStack(alignment: .top) {
            Group {
                Text(model.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .appFontRegularSize14()
        }
        .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
    }

    @ViewBuilder func trailingAccessoryImage() -> some View {
        AppAssets.Shared.sharedChevronRight.imageSwiftUI
            .frame(width: 20, height: 20)
    }
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupsModuleCommodityGroupRow_Previews: PreviewProvider {
    private static let model1: CommodityGroupModel = .init(
        id: UUID().uuidString,
        name: "Coffe",
        commodities: []
    )
    private static let model2: CommodityGroupModel = .init(
        id: UUID().uuidString,
        name: "Rubber",
        commodities: []
    )

    static var previews: some View {
        VStack {
            CommodityGroupRow(model: model1)
            CommodityGroupRow(model: model2)
        }
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
