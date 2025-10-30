//
//  TransactionDetails+SuppliersHistoryList.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 12.06.2025.
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
import typealias Utility.IdentifiedArrayOf

private typealias Module = TransactionDetailsModule
private typealias SuppliersHistoryList = Module.SuppliersHistoryList
private typealias Localization = AppLocale.TransactionDetails.SuppliersHistory

// MARK: - SuppliersHistoryList
extension Module {
    struct SuppliersHistoryList: View {
        let items: IdentifiedArrayOf<SupplierTransactionModel>
        let didTapViewAll: () -> Void
        let didTapSupplyRow: (SupplierTransactionModel) -> Void

        var body: some View {
            content()
        }
    }
}

// MARK: - Private Layout
private extension SuppliersHistoryList {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 12) {
            header()
                .padding(.horizontal, 16)
            SuppliersHistoryModule.ListView(
                items: items,
                didTapSupplyRow: didTapSupplyRow
            )
        }
    }

    @ViewBuilder func header() -> some View {
        HStack {
            Text(Localization.title)
                .appFontMediumSize18()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Spacer()
            Button {
                didTapViewAll()
            } label: {
                Module.TrailingAccessoryImage()
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsSuppliersHistoryList_Previews: PreviewProvider {
    private static var transaction: SupplierTransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        type: .producer,
        status: .accepted,
        traceability: .fullTraceability,
        location: .gps,
        latitude: 111.0,
        longitude: 222.0,
        volume: 5.0,
        isBuyingFromFarmer: false,
        commodity: .init(
            id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
            code: "3298",
            name: "Roasted beans",
            unit: "buckets",
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: .init(
            id: "id1",
            username: "username1",
            gadgets: []
        ),
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1"
    )
    private static var transaction2: SupplierTransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970a223",
        createdAt: "2025-06-07T23:15:42.205456Z",
        type: .producer,
        status: .accepted,
        traceability: .fullTraceability,
        location: .gps,
        latitude: 111.0,
        longitude: 222.0,
        volume: 55.0,
        isBuyingFromFarmer: false,
        commodity: .init(
            id: "257f49ed-7963-49ac-ac31-e3fe7752e2f5",
            code: "3298",
            name: "Roasted beans",
            unit: "buckets",
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: .init(
            id: "id1",
            username: "username1",
            gadgets: []
        ),
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1"
    )

    static var previews: some View {
        VStack {
            SuppliersHistoryList(
                items: [transaction, transaction2],
                didTapViewAll: { },
                didTapSupplyRow: { _ in }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
