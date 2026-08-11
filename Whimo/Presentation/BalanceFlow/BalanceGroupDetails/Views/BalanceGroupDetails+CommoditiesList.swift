//
//  BalanceGroupDetails+CommoditiesList.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.08.2025.
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

private typealias Module = BalanceGroupDetailsModule
private typealias CommoditiesList = Module.CommoditiesList

// MARK: - CommoditiesList
extension Module {
    struct CommoditiesList: View {
        // MARK: - Properties
        let commodityGroup: CommodityGroupModel
        let connectionReachable: Bool
        let didTapConvert: (CommodityGroupModel.Commodity) -> Void

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension CommoditiesList {
    @ViewBuilder func content() -> some View {
//        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(commodityGroup.commodities) { item in
                    listRow(item: item)
                }
            }
//        }
    }

    @ViewBuilder func listRow(item: CommodityGroupModel.Commodity) -> some View {
        VStack(spacing: .zero) {
            Module.CommodityRow(
                item: item,
                connectionReachable: connectionReachable,
                didTapConvert: { didTapConvert(item) }
            )
            if item.id == commodityGroup.commodities.last?.id {
                DefaultDivider()
            } else {
                DashDivider()
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupDetailsCommoditiesList_Previews: PreviewProvider {
    private static let model1: CommodityGroupModel = .init(
        id: UUID().uuidString,
        name: "Coffe",
        commodities: [
            .init(
                id: "1",
                code: "123",
                name: "test 1",
                unit: "kg",
                balance: nil,
                hasRecipe: true,
                group: .init(id: "1", name: "Test Group")
            ),
            .init(
                id: "2",
                code: "456",
                name: "test 2",
                unit: "buckets",
                balance: nil,
                hasRecipe: true,
                group: .init(id: "1", name: "Test Group")
            )
        ]
    )
    static var previews: some View {
        VStack {
            CommoditiesList(commodityGroup: model1, connectionReachable: true, didTapConvert: { _ in })
        }
        .background(AppColors.Gray.gray5.colorSwiftUI)
    }
}
#endif
