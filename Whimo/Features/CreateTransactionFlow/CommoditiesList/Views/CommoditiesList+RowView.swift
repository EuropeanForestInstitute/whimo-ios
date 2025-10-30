//
//  CommoditiesList+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.05.2025.
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

private typealias Module = CommoditiesListModule
private typealias RowView = Module.RowView

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let row: CommodityGroupModel
        @Binding var selectedRow: CommodityGroupModel.Commodity?

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        DynamicDisclosureGroup {
            list()
                .background(AppColors.Other.white.colorSwiftUI)
        } label: {
            Text(row.name)
        }
    }

    @ViewBuilder func list() -> some View {
        VStack(spacing: .zero) {
            ForEach(row.commodities) { item in
                listRow(item: item)
            }
        }
    }

    @ViewBuilder func listRow(item: CommodityGroupModel.Commodity) -> some View {
        VStack(spacing: .zero) {
            let binding: Binding<CommodityGroupModel.Commodity?> = .init {
                selectedRow
            } set: { newValue in
                if let newValue {
                    selectedRow = newValue
                }
            }

            Module.RowListItem(item: item, selectedItem: binding)
            if item.id == row.commodities.last?.id {
                DefaultDivider()
            } else {
                DashDivider()
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CommoditiesListRowView_Previews: PreviewProvider {
    struct Container: View {
        private let row: CommodityGroupModel = .init(
            id: "1",
            name: "Cocoa",
            commodities: [
                .init(
                    id: "1",
                    code: "1801",
                    name: "Cocoa beans, whole or broken, raw or roasted",
                    unit: "",
                    balance: nil
                ),
                .init(
                    id: "2",
                    code: "1802",
                    name: "Cocoa shells, husks, skins and other cocoa waste",
                    unit: "",
                    balance: nil
                )
            ]
        )

        @State var selectedRow: CommodityGroupModel.Commodity?

        var body: some View {
            RowView(row: row, selectedRow: $selectedRow)
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
