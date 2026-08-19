//
//  TransactionDetails+RecipientInfoPopup.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 16.05.2025.
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

private typealias Module = TransactionDetailsModule
private typealias CounterpartyInfoPopup = Module.RecipientInfoPopup
private typealias Localization = AppLocale.TransactionDetails.Popups.CounterpartyInfo

// MARK: - RecipientInfoPopup
extension Module {
    struct RecipientInfoPopup: View {
        // MARK: - Properties
        let transaction: TransactionModel

        // MARK: - Private Properties
        private var recipient: UserModel? {
            switch transaction.action {
                case .buy:
                    return transaction.seller
                case .sell:
                    return transaction.buyer
            }
        }
        private func getGadgetId(type: UserModel.GadgetModel.GadgetType) -> String? {
            for gadget in recipient?.gadgets ?? [] where gadget.type == type {
                return gadget.identifier
            }
            return nil
        }

        private var username: String {
            let username = recipient?.username ?? "-"
            if username == UserModel.kOfflineModeRecipientName {
                return AppLocale.TransactionDetails.Offline.usernameNotAvaible
            }
            return username
        }
        private var email: String? { getGadgetId(type: .email) }
        private var phone: String? { getGadgetId(type: .phone) }

        // MARK: - Body
        var body: some View {
            content()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.Gray.gray5.colorSwiftUI)
                }
        }
    }
}

// MARK: - Private Layout
private extension CounterpartyInfoPopup {
    @ViewBuilder func content() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Group {
                infoRow(
                    icon: AppAssets.AccountInfo.accountInfoUserIcon.imageSwiftUI,
                    title: username,
                    subtitle: Localization.Row.UserID.title
                )
                if let email {
                    infoRow(
                        icon: AppAssets.AccountInfo.accountInfoEmailIcon.imageSwiftUI,
                        title: email,
                        subtitle: Localization.Row.Email.title
                    )
                }
                if let phone {
                    infoRow(
                        icon: AppAssets.AccountInfo.accountInfoPhoneIcon.imageSwiftUI,
                        title: phone,
                        subtitle: Localization.Row.Phone.title
                    )
                }
            }
            .background(AppColors.Other.white.colorSwiftUI)
        }
    }

    @ViewBuilder func infoRow(
        icon: Image,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            icon
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                Text(subtitle)
                    .appFontRegularSize14()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsTraceabilityPopup_Previews: PreviewProvider {
    private static var transaction: TransactionModel = .init(
        id: "621bfc60-9950-41ee-954c-96ee7970b493",
        createdAt: "2025-06-07T23:15:42.205456Z",
        expiresAt: nil,
        updatedAt: nil,
        type: .producer,
        status: .accepted,
        action: .sell,
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
            gadgets: [
                .init(
                    identifier: "preview@email.com",
                    type: .email,
                    isVerified: true
                )
            ]
        ),
        createdById: "id1",
        persistingData: .sync()
    )

    static var previews: some View {
        VStack {
            CounterpartyInfoPopup(transaction: transaction)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
