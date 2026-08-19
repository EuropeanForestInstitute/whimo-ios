//
//  TransactionDetails+ListView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 18.06.2025.
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
import Utility

private typealias Module = TransactionDetailsModule
private typealias ListView = Module.ListView
private typealias Localization = AppLocale.TransactionDetails

extension Module {
    struct ListView: View {
        // MARK: - Properties
        let rows: IdentifiedArrayOf<Row>
        let transaction: TransactionModel
        let pieChartData: TransactionTraceabilityModel?

        let didTapAddMissignGeodata: () -> Void
        let didTapTraceabilityStatus: () -> Void
        let didTapShowRecipientInfo: () -> Void
        let didTapTransactionStatus: () -> Void

        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        private var dateFormatter: DateTimeFormatter {
            .transaction(locale: currentLocalize.locale)
        }

        private var commodityTypeText: String {
            "\(transaction.commodity.code) \(transaction.commodity.name), \(transaction.volume)\(transaction.commodity.unit)"
        }
        private var buyerIDText: String? {
            if let buyerId = transaction.buyer?.username {
                if buyerId == UserModel.kOfflineModeRecipientName {
                    return Localization.Offline.usernameNotAvaible
                }
                if transaction.action == .buy {
                    return Localization.Row.BuyerID.descriptionYou(buyerId)
                } else {
                    return Localization.Row.BuyerID.descriptionToYou(buyerId)
                }
            }

            return nil
        }
        private var supplierIDText: String? {
            if let sellerId = transaction.seller?.username {
                if sellerId == UserModel.kOfflineModeRecipientName {
                    return Localization.Offline.usernameNotAvaible
                }
                if transaction.action == .sell {
                    return Localization.Row.SupplierInformation.descriptionYou(sellerId)
                } else {
                    return Localization.Row.SupplierInformation.descriptionToYou(sellerId)
                }
            }

            return nil
        }
        private var farmGeodataDescriptionText: String {
            if let source = transaction.location?.rawValue {
                Localization.Row.FarmGeodata.descriptionProvided(source)
            } else {
                Localization.Row.FarmGeodata.descriptionMissing
            }
        }

        private var farmGeodataDescriptionTextColor: Color {
            if transaction.location?.rawValue != nil {
                AppColors.Gray.gray90.colorSwiftUI
            } else {
                AppColors.Expanded.expandedError.colorSwiftUI
            }
        }

        private var transactionDate: String {
            dateFormatter.format(textDate: transaction.createdAt) ?? "N/A"
        }

        private var expiresDate: String? {
            guard let expiresAt = transaction.expiresAt else { return nil }

            return dateFormatter.format(textDate: expiresAt)
        }

        // MARK: - Body
        var body: some View {
            contant()
        }
    }
}

// MARK: - Private Methods
private extension ListView {
    // swiftlint:disable:next function_body_length
    @ViewBuilder func contant() -> some View {
        VStack(spacing: .zero) {
            ForEach(rows) { item in
                switch item {
                    case .commodityType:
                        vstackRow(
                            title: item.title,
                            description: commodityTypeText
                        )
                        DefaultDivider()
                    case .farmGeodata:
                        if transaction.location == nil {
                            Button {
                                didTapAddMissignGeodata()
                            } label: {
                                labeledRow(title: item.title) {
                                    HStack(spacing: 8) {
                                        defaultDescription(
                                            text: farmGeodataDescriptionText,
                                            textColor: farmGeodataDescriptionTextColor,
                                            enableAccessory: true
                                        )
                                    }
                                }
                            }
                        } else {
                            labeledRow(title: item.title) {
                                HStack(spacing: 8) {
                                    defaultDescription(
                                        text: farmGeodataDescriptionText,
                                        textColor: farmGeodataDescriptionTextColor,
                                        enableAccessory: false
                                    )
                                }
                            }
                        }
                        DefaultDivider()
                    case .traceabilityStatus:
                        if let traceability = transaction.traceability {
                            Button {
                                didTapTraceabilityStatus()
                            } label: {
                                VStack(spacing: .zero) {
                                    Module.TraceabilityStatusRow(title: item.title, traceabilityStatus: traceability)
                                    if let pieChartData,
                                       !pieChartData.items.isEmpty,
                                       transaction.status != .pending {
                                        Module.ChartInfoView(pieChartData: pieChartData)
                                            .padding(.bottom, 16)
                                    }
                                }
                                .background(AppColors.Other.white.colorSwiftUI)
                            }
                            DefaultDivider()
                        }
                    case .buyerID:
                        if let buyerIDText {
                            if transaction.action == .buy {
                                labeledRow(title: item.title) {
                                    defaultDescription(text: buyerIDText, enableAccessory: false)
                                }
                            } else {
                                Button {
                                    didTapShowRecipientInfo()
                                } label: {
                                    labeledRow(title: item.title) {
                                        HStack(spacing: 8) {
                                            Module.RowBoldDescription(text: buyerIDText)
                                            Module.TrailingAccessoryImage()
                                        }
                                    }
                                }
                            }
                            DefaultDivider()
                        }
                    case .supplierInformation:
                        if let supplierIDText {
                            if transaction.action == .sell {
                                labeledRow(title: item.title) {
                                    defaultDescription(text: supplierIDText, enableAccessory: false)
                                }
                            } else {
                                Button {
                                    didTapShowRecipientInfo()
                                } label: {
                                    labeledRow(title: item.title) {
                                        HStack(spacing: 8) {
                                            Module.RowBoldDescription(text: supplierIDText)
                                            Module.TrailingAccessoryImage()
                                        }
                                    }
                                }
                            }
                            DefaultDivider()
                        }
                    case .transactionStatus:
                        Button {
                            didTapTransactionStatus()
                        } label: {
                            labeledRow(title: item.title) {
                                HStack(spacing: 8) {
                                    Module.RowStatusDescription(status: transaction.status)
                                    Module.TrailingAccessoryImage()
                                }
                            }
                        }
                        DefaultDivider()
                    case .transactionDate:
                        labeledRow(title: item.title) {
                            defaultDescription(text: transactionDate, enableAccessory: false)
                        }
                        DefaultDivider()
                    case .expireDate:
                        if let expiresDate {
                            labeledRow(title: item.title) {
                                defaultDescription(text: expiresDate, enableAccessory: false)
                            }
                            DefaultDivider()
                        }
                }
            }
        }
    }

    // MARK: - Rows
    @ViewBuilder func vstackRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Group {
                Module.RowTitle(text: title)
                Module.RowDescription(text: description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.Other.white.colorSwiftUI)
    }

    @ViewBuilder func labeledRow(title: String, description: String) -> some View {
        LabeledContent {
            HStack(spacing: 8) {
                Module.RowDescription(text: description)
                Module.TrailingAccessoryImage()
            }
        } label: {
            Module.RowTitle(text: title)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(AppColors.Other.white.colorSwiftUI)
    }

    @ViewBuilder func labeledRow(title: String, @ViewBuilder description: () -> some View) -> some View {
        LabeledContent {
            HStack(spacing: 8) {
                description()
            }
        } label: {
            Module.RowTitle(text: title)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(AppColors.Other.white.colorSwiftUI)
    }

    @ViewBuilder func defaultDescription(
        text: String,
        textColor: Color = AppColors.Gray.gray90.colorSwiftUI,
        enableAccessory: Bool = true
    ) -> some View {
        HStack(spacing: 8) {
            Module.RowDescription(text: text, textColor: textColor)
            if enableAccessory {
                Module.TrailingAccessoryImage()
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsListView_Previews: PreviewProvider {
    private static var transaction: TransactionModel = .init(
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
            balance: nil,
            hasRecipe: false,
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

    private static var transaction2: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .buy,
        traceability: nil,
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
            balance: nil,
            hasRecipe: false,
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

    private static var pieChartData: TransactionTraceabilityModel = .init(items: [
        .full(20),
        .conditional(10),
        .partial(30),
        .incomplete(5)
    ])

    static var previews: some View {
        VStack {
            ListView(
                rows: .init(uniqueElements: Module.Row.plainStatusCases),
                transaction: transaction,
                pieChartData: pieChartData,
                didTapAddMissignGeodata: { },
                didTapTraceabilityStatus: { },
                                        didTapShowRecipientInfo: { },
                didTapTransactionStatus: { }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDisplayName("Plain")

        VStack {
            ListView(
                rows: .init(uniqueElements: Module.Row.plainStatusCases),
                transaction: transaction,
                pieChartData: .init(items: []),
                didTapAddMissignGeodata: { },
                didTapTraceabilityStatus: { },
                                        didTapShowRecipientInfo: { },
                didTapTransactionStatus: { }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDisplayName("Empty Pie Chart")

        VStack {
            ListView(
                rows: .init(uniqueElements: Module.Row.plainStatusCases),
                transaction: transaction2,
                pieChartData: .init(items: []),
                didTapAddMissignGeodata: { },
                didTapTraceabilityStatus: { },
                                        didTapShowRecipientInfo: { },
                didTapTransactionStatus: { }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
        .previewDisplayName("Empty Traceability")
    }
}
#endif
