//
//  ConvertCommodity+ListView.swift
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
        let items: IdentifiedArrayOf<ConvertTypeModel>
        let didTapItem: (ConvertTypeModel) -> Void

        // MARK: - Body
        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension ListView {
    @ViewBuilder func content() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        didTapItem(item)
                    } label: {
                        Module.RowView(model: item)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct ConvertCommodityListListView_Previews: PreviewProvider {
    private static let items: [Module.ConvertTypeModel] = [
        .decaffeinate,
        .roastCoffe,
        .longType
    ]

    static var previews: some View {
        VStack {
            ListView(items: .init(uniqueElements: items), didTapItem: { _ in })
        }
//        .frame(height: UIScreen.main.bounds.height)
//        .background(.red.opacity(0.5))
    }
}
#endif
