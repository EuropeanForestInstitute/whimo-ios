//
//  TransactionModel+Extension.swift
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

// MARK: - Status
extension TransactionModel.Status {
    private typealias Localization = AppLocale.Home.Row
    private typealias Assets = AppAssets.Transactions

    var title: String {
        switch self {
            case .accepted:
                Localization.Status.accepted
            case .rejected:
                Localization.Status.reject
            case .pending:
                Localization.Status.pending
            case .noResponse:
                Localization.Status.noResponse
            case .recorded:
                Localization.Status.recorded
            case .automatic:
                Localization.Status.automatic
        }
    }

    var titleColor: Color {
        switch self {
            case .accepted:
                AppColors.Expanded.expandedSuccess.colorSwiftUI
            case .rejected:
                AppColors.Expanded.expandedError.colorSwiftUI
            case .pending:
                AppColors.Expanded.expandedWarning.colorSwiftUI
            case .noResponse:
                AppColors.Gray.gray50.colorSwiftUI
            case .recorded:
                AppColors.Primary.primaryBerryBlue.colorSwiftUI
            case .automatic:
                AppColors.Gray.gray90.colorSwiftUI
        }
    }

    var backgroundColor: Color {
        switch self {
            case .accepted:
                AppColors.Other.lightGreen.colorSwiftUI
            case .rejected:
                AppColors.Other.lightRed.colorSwiftUI
            case .pending:
                AppColors.Other.lightOrange.colorSwiftUI
            case .noResponse:
                AppColors.Gray.gray5.colorSwiftUI
            case .recorded:
                AppColors.Other.lightBlue.colorSwiftUI
            case .automatic:
                AppColors.Gray.gray10.colorSwiftUI
        }
    }

    var details: String {
        typealias Localization = AppLocale.TransactionDetails.Popups.TransactionStatus

        switch self {
            case .accepted:
                return Localization.Accepted.details
            case .noResponse:
                return Localization.NoResponse.details
            case .recorded:
                return Localization.Recorded.details
            case .automatic:
                return Localization.Automatic.details
            case .rejected:
                return Localization.Rejected.details
            case .pending:
                return Localization.Pending.details
        }
    }
}

// MARK: - Action
extension TransactionModel.Action {
    private typealias Assets = AppAssets.Transactions

    var image: Image {
        switch self {
            case .buy:
                Assets.transactionsBuyIcon.imageSwiftUI
            case .sell:
                Assets.transactionsSellIcon.imageSwiftUI
        }
    }
}

// MARK: - Traceability
extension TransactionModel.Traceability {
    private typealias Localization = AppLocale.TransactionDetails.Row.TraceabilityStatus.Cases

    var title: String {
        switch self {
            case .fullTraceability:
                Localization.FullTraceability.title
            case .conditionalTraceability:
                Localization.ConditionalTraceability.title
            case .partialTraceability:
                Localization.PartialTraceability.title
            case .incompleteTraceability:
                Localization.IncompleteTraceability.title
        }
    }

    var fullTitle: String { Localization.fullTitle(title) }

    var primaryColor: Color {
        switch self {
            case .fullTraceability:
                AppColors.Expanded.expandedSuccess.colorSwiftUI
            case .conditionalTraceability:
                AppColors.Primary.primarySeaBlue.colorSwiftUI
            case .partialTraceability:
                AppColors.Primary.primaryMulberryPurple.colorSwiftUI
            case .incompleteTraceability:
                AppColors.Primary.primaryMidnightBlue.colorSwiftUI
        }
    }

    var secondaryColor: Color { primaryColor.opacity(0.1) }
}
