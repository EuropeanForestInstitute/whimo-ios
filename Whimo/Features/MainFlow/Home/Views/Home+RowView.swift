//
//  Home+RowView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.05.2025.
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

private typealias Module = HomeModule
private typealias RowView = Module.RowView
private typealias Localization = AppLocale.Home.Row

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let model: TransactionModel
        let didTapAddGeolocation: () -> Void

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        private let decimalFormatter: DecimalFormatter = .default
        private var dateFormatter: DateTimeFormatter {
            .transaction(locale: currentLocalize.locale)
        }

        private var titleText: String {
            "\(model.commodity.group.name), \(model.volume)\(model.commodity.unit)"
        }

        private var dateText: String {
            dateFormatter.format(textDate: model.createdAt) ?? ""
        }

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
private extension RowView {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 8) {
            statusImage()
            text()
            Spacer()
            accessoriesView()
        }
        .padding(16)
    }

    @ViewBuilder func statusImage() -> some View {
        model.action.image
            .frame(width: 28, height: 26)
    }

    @ViewBuilder func text() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                Text(dateText)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            }
            if model.status == .automatic && model.location == nil {
                Button {
                    didTapAddGeolocation()
                } label: {
                    Text(Localization.Buttons.addInfo)
                        .appFontMediumSize16()
                        .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
                }
            }
        }
    }

    @ViewBuilder func accessoriesView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            syncStatusLabel()
            statusLabel()
        }
    }

    @ViewBuilder func syncStatusLabel() -> some View {
        switch model.persistingData.state {
            case .onDisk:
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundStyle(AppColors.Gray.gray70.colorSwiftUI)
            case .uploading:
                ProgressView()
            default:
                EmptyView()
        }
    }

    @ViewBuilder func statusLabel() -> some View {
        Text(model.status.title)
            .appFontMediumSize14()
            .foregroundStyle(model.status.titleColor)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(model.status.backgroundColor)
            }
    }
}

// MARK: - Previews
#if !RELEASE
struct HomeRowView_Previews: PreviewProvider {
    private static let item1: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
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
        createdById: "id1",
        persistingData: .sync()
    )
    private static let item2: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .automatic,
        action: .buy,
        traceability: .fullTraceability,
        location: nil,
        farmLatitude: nil,
        farmLongitude: nil,
        transactionLatitude: nil,
        transactionLongitude: nil,
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
        createdById: "id1",
        persistingData: .sync()
    )
    private static let item3: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
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
        createdById: "id1",
        persistingData: .onDisk()
    )

    private static let item4: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: .fullTraceability,
        location: .gps,
        farmLatitude: 111.0,
        farmLongitude: 222.0,
        transactionLatitude: nil,
        transactionLongitude: nil,
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
        createdById: "id1",
        persistingData: .uploading()
    )

    static var previews: some View {
        VStack(spacing: 16) {
            RowView(model: item1) { }
            RowView(model: item2) { }
            RowView(model: item3) { }
            RowView(model: item4) { }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
