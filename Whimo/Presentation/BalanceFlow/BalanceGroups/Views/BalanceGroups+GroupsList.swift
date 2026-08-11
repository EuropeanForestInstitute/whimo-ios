//
//  BalanceGroups+GroupsList.swift
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
import Utility

private typealias Module = BalanceGroupsModule
private typealias GroupsList = Module.GroupsList

// MARK: - GroupsList
extension Module {
    struct GroupsList: View {
        // MARK: - Properties
        let list: IdentifiedArrayOf<CommodityGroupModel>
        let didTapCommodityGroup: (CommodityGroupModel) -> Void

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension GroupsList {
    @ViewBuilder func content() -> some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(list) { model in
                    Button {
                        didTapCommodityGroup(model)
                    } label: {
                        Module.CommodityGroupRow(model: model)
                    }
                    DefaultDivider()
                }
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct BalanceGroupsModuleGroupsList_Previews: PreviewProvider {
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
            GroupsList(
                list: [model1, model2],
                didTapCommodityGroup: { _ in }
            )
        }
        .background(.red.opacity(0.5))
    }
}
#endif
