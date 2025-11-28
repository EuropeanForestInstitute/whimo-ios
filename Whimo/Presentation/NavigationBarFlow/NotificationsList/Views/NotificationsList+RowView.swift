//
//  NotificationsList+RowView.swift
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
import Resources

private typealias Module = NotificationsListModule
private typealias RowView = Module.RowView
private typealias Localization = AppLocale.NotificationsList.Row

// MARK: - RowView
extension Module {
    struct RowView: View {
        // MARK: - Properties
        let model: Notifications.Model
        let didTapViewDetails: () -> Void

        // MARK: - Private Properties
        private let timeAgoFormatter: TimeAgoFormatter = .init()

        private var titleText: String {
            switch model.type {
                case .transactionPending:
                    Localization.Pending.title
                case .transactionAccepted:
                    Localization.Accepted.title
                case .transactionRejected:
                    Localization.Rejected.title
                case .transactionExpired:
                    Localization.Expired.title
                case .geodataMissing:
                    Localization.GeodataMissing.title
            }
        }
        private var detailsText: String {
            "\(model.data.commodity.code) \(model.data.commodity.name), \(model.data.volume)\(model.data.commodity.unit)"
        }
        private var dateText: String { timeAgoFormatter.timeAgo(from: model.createdAt) ?? "N/A" }

        // MARK: - Body
        var body: some View {
            content()
                .background(AppColors.Other.white.colorSwiftUI)
        }
    }
}

// MARK: - Private Layout
private extension RowView {
    @ViewBuilder func content() -> some View {
        VStack(spacing: 12) {
            HStack {
                infoText()
                Spacer(minLength: 48)
                timeLabel()
            }
            if model.type.requireActions {
                detailsButton()
            }
        }
        .padding(16)
    }

    @ViewBuilder func infoText() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .appFontMediumSize16()
                .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
            Text(detailsText)
                .appFontRegularSize16()
                .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
        }
    }

    @ViewBuilder func timeLabel() -> some View {
        Text(dateText)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
    }

    @ViewBuilder func detailsButton() -> some View {
        HStack {
            Button {
                didTapViewDetails()
            } label: {
                Text(Localization.Buttons.viewDetails)
                    .appFontMediumSize16()
                    .foregroundStyle(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            }
            Spacer()
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct NotificationsListRowView_Previews: PreviewProvider {
    static private let item1: Notifications.Model = .init(
        id: "0cf37e60-002d-40a6-b498-1dac41b7f41a",
        data: .init(
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
        ),
        createdAt: "2025-06-23T15:11:31.881402Z",
        type: .transactionAccepted,
        status: .pending
    )

    static private let item2: Notifications.Model = .init(
        id: "0cf37e60-002d-40a6-b498-1dac41b7f41a",
        data: .init(
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
        ),
        createdAt: "2025-06-23T15:11:31.881402Z",
        type: .geodataMissing,
        status: .pending
    )

    static var previews: some View {
        VStack(spacing: 24) {
            RowView(model: item1) { }
            RowView(model: item2) { }
        }
        .frame(height: UIScreen.main.bounds.height)
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.5))
    }
}
#endif
