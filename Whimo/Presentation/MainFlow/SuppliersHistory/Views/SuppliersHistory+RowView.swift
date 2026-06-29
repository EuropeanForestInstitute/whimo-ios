//
//  SuppliersHistory+RowView.swift
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
import CommonUI
import Resources

private typealias Module = SuppliersHistoryModule
private typealias RowView = Module.RowView
private typealias Assets = AppAssets.TransactionDetails
private typealias Localization = AppLocale.SuppliersHistory.Row

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Public Properties
        let transaction: SupplierTransactionModel
        let didTap: () -> Void

        // MARK: - Private Properties
        // MARK: - Private Properties
        @AppStorage(.currentLocalize)
        private var currentLocalize: LocalizeKeys = .english

        private let decimalFormatter: DecimalFormatter = .default
        private var dateFormatter: DateTimeFormatter {
            .transaction(locale: currentLocalize.locale)
        }

        private var titleText: String {
            var id: String = ""
            if let sellerId = transaction.seller?.username {
                id = "#\(sellerId.prefix(8))..."
            }

            switch transaction.type {
                case .producer:
                    return Localization.titleInitial(id)
                case .downstream, .conversion:
                    return Localization.title(id)
            }
        }
        private var dateText: String {
            dateFormatter.format(textDate: transaction.createdAt) ?? "N/A"
        }
        private var volumeText: String {
            let volume = decimalFormatter.format(value: "\(transaction.volume)")
            return "\(volume)\(transaction.commodity.unit)"
        }

        // MARK: - Body
        var body: some View {
            if transaction.type == .producer {
                content()
                    .background(AppColors.Other.white.colorSwiftUI)
            } else {
                Button(action: didTap) {
                    content()
                        .background(AppColors.Other.white.colorSwiftUI)
                }
            }
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(
                action: { didTapStatus(transaction.traceability) },
                label: leadingAccessory
            )
            textView()
            Spacer()
            HStack(alignment: .center, spacing: 12) {
                volumeView()
                if transaction.type == .downstream {
                    trailingAccessory()
                }
            }
        }
        .padding(16)
    }

    @ViewBuilder func leadingAccessory() -> some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(AppColors.Gray.gray10.colorSwiftUI, lineWidth: 1)
            .frame(width: 24, height: 24)
            .overlay {
                Assets.transactionDetailsSupplyBadge.imageSwiftUI
                    .renderingMode(.template)
                    .foregroundStyle(transaction.traceability?.primaryColor ?? AppColors.Gray.gray10.colorSwiftUI)
                    .frame(width: 16, height: 16)
            }
            .background {
                BackgroundShadowView(style: .card)
            }
    }

    @ViewBuilder func trailingAccessory() -> some View {
        Assets.transactionDetailsArrowRight.imageSwiftUI
            .frame(width: 20, height: 20)
    }

    @ViewBuilder func textView() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleText)
                .appFontMediumSize14()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Text(dateText)
                .appFontRegularSize14()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder func volumeView() -> some View {
        Text(volumeText)
            .appFontMediumSize14()
            .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
    }
}

// MARK: - Private Methods
private extension RowView {
    func didTapStatus(_ status: TransactionModel.Traceability?) {
        guard let status else { return }

        @Inject(\.alertManager) var alertManager

        typealias Localization = AppLocale.TransactionDetails.Popups.TraceabilityStatus

        let popup: Module.TraceabilityStatusPopup = .init(status: status)
        alertManager.show(.init(
            title: Localization.title,
            contentView: .init(popup)
        ))
    }
}

// MARK: - Previews
#if !RELEASE
struct SuppliersHistoryRowView_Previews: PreviewProvider {
    private static var transaction: SupplierTransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        updatedAt: nil,
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
            balance: nil,
            hasRecipe: false,
            group: .init(
                id: "eab07411-6b28-4eee-8973-d57d30c5ee96",
                name: "Coffee"
            )
        ),
        seller: nil,
        buyer: .init(
            id: "id2",
            username: "username2",
            gadgets: []
        ),
        createdById: "id1"
    )

    static var previews: some View {
        VStack {
            RowView(transaction: transaction) { }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
