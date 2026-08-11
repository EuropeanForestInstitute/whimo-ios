//
//  ConvertCommodityList+ListView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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

private typealias Module = ConvertCommodityListModule
private typealias ListView = Module.ListView

// MARK: - MainView
extension Module {
    struct ListView: View {
        let items: IdentifiedArrayOf<ConversionRuleModel>
        let didTapItem: (ConversionRuleModel) -> Void
        let onNextPageLoad: (_ condition: @autoclosure () -> Bool) -> Void

        // MARK: - Init
        init(
            items: IdentifiedArrayOf<ConversionRuleModel>,
            didTapItem: @escaping (ConversionRuleModel) -> Void,
            onNextPageLoad: @escaping (_ condition: @autoclosure () -> Bool) -> Void = { _ in }
        ) {
            self.items = items
            self.didTapItem = didTapItem
            self.onNextPageLoad = onNextPageLoad
        }

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension ListView {
    @ViewBuilder func content() -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                Button {
                    didTapItem(item)
                } label: {
                    Module.RowView(model: item)
                }
                .padding(.horizontal, 16)
                .onAppear { onNextPageLoad(item.id == items.last?.id) }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityListListView_Previews: PreviewProvider {
    private static let items: [ConversionRuleModel] = [
        .init(
            id: "342c799c-6b32-4c38-8033-085d18b18b2c",
            name: "Roast coffee",
            inputs: [
                .init(
                    id: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
                    commodity: .init(
                        id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
                        code: "1401",
                        name: "Coffee beans",
                        unit: "kgs",
                        balance: nil,
                        hasRecipe: false,
                        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
                    ),
                    quantity: 10.0
                )
            ],
            outputs: [
                .init(
                    id: "26283af0-17da-4c96-8331-dfb372822f87",
                    commodity: .init(
                        id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
                        code: "3298",
                        name: "Roasted beans",
                        unit: "buckets",
                        balance: nil,
                        hasRecipe: false,
                        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
                    ),
                    quantity: 5.0
                )
            ]
        ),
        .init(
            id: "342c799c-6b32-4c38-8033-085d18b18b2d",
            name: "Roast coffee 2",
            inputs: [
                .init(
                    id: "2216e6c5-a30b-4f25-9af6-b62eb28cb774",
                    commodity: .init(
                        id: "f505b79b-e20f-4cba-9236-a4a6079053cd",
                        code: "1401",
                        name: "Coffee beans",
                        unit: "kgs",
                        balance: nil,
                        hasRecipe: false,
                        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
                    ),
                    quantity: 10.0
                )
            ],
            outputs: [
                .init(
                    id: "26283af0-17da-4c96-8331-dfb372822f87",
                    commodity: .init(
                        id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
                        code: "3298",
                        name: "Roasted beans",
                        unit: "buckets",
                        balance: nil,
                        hasRecipe: false,
                        group: .init(id: "eab07411-6b28-4eee-8973-d57d30c5ee96", name: "Coffee")
                    ),
                    quantity: 5.0
                )
            ]
        )
    ]

    static var previews: some View {
        VStack {
            ListView(items: .init(uniqueElements: items), didTapItem: { _ in })
        }
    }
}
#endif
