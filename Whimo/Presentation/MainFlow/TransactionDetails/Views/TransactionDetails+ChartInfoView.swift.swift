//
//  TransactionDetails+ChartInfoView.swift
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
import Utility
import Resources

private typealias Module = TransactionDetailsModule
private typealias ChartInfoView = Module.ChartInfoView
private typealias Localization = AppLocale.TransactionDetails.Row.TraceabilityStatus

// MARK: - ChartView
extension Module {
    struct ChartInfoView: View {
        private enum Constants {
            @available(iOS 17.0, *)
            static let modernChartSpacing: CGFloat = 1

            @available(iOS, deprecated: 17.0, message: "Use `modernChartSpacing` property instead.")
            static let legacyChartSpacing: CGFloat = 6
        }

        // MARK: - Properties
        let pieChartData: TransactionTraceabilityModel?

        // MARK: - Private Properties
        private var datasource: [TransactionTraceabilityModel.Traceability] {
            (pieChartData?.items ?? []).filter { $0.value > .zero }
        }

        private var chartDatasource: IdentifiedArrayOf<ChartView<TransactionTraceabilityModel.Traceability, Int>.Sector> {
            .init(
                uniqueElements: datasource
                    .reversed()
                    .map {
                        .init(
                            model: $0,
                            title: $0.status.title,
                            chartValue: Int($0.value),
                            color: $0.status.primaryColor
                        )
                    }
            )
        }

        private var traceabilityTotalAmount: Int {
            Int(datasource.reduce(into: .zero) { partialResult, item in
                partialResult += item.value
            })
        }

        private var chartTitleText: AttributedString {
            AttributedStringBuilder.build(from: [
                (
                    "\(traceabilityTotalAmount)",
                    .init([
                        .font: AppFonts.FiraSans.medium.font(size: 16),
                        .foregroundColor: AppColors.Gray.gray90.color
                    ])
                ),
                (
                    Localization.Chart.titleAttachment,
                    .init([
                        .font: AppFonts.FiraSans.regular.font(size: 12),
                        .foregroundColor: AppColors.Gray.gray60.color
                    ])
                ),
            ])
        }

        private var highestTraceability: TransactionTraceabilityModel.Traceability {
            datasource.max(by: { $0.value < $1.value }) ?? .full(0)
        }

        // MARK: - Init
        init(pieChartData: TransactionTraceabilityModel?) {
            self.pieChartData = pieChartData
        }

        // MARK: - Body
        var body: some View {
            content()
                .background(AppColors.Other.white.colorSwiftUI)
        }
    }
}

// MARK: - Private Layout
private extension ChartInfoView {
    @ViewBuilder func content() -> some View {
        HStack {
            chartLandscapeView()
            Spacer()
        }
    }

    @ViewBuilder func chartLandscapeView() -> some View {
        HStack(spacing: 12) {
            Spacer()
            if highestTraceability.value > .zero {
                chartView()
                    .overlay {
                        Text(chartTitleText)
                            .multilineTextAlignment(.center)
                    }
            }
            ChartLegend(sectors: chartDatasource)
            Spacer()
        }
    }

    @ViewBuilder func chartView() -> some View {
        Group {
            if #available(iOS 17.0, *) {
                ChartView(
                    sectors: chartDatasource,
                    thickness: 32,
                    cornerRadius: 1.6,
                    spacing: Constants.modernChartSpacing
                )
            } else {
                ChartView(
                    sectors: chartDatasource,
                    thickness: 32,
                    cornerRadius: 1.6,
                    spacing: Constants.legacyChartSpacing
                )
            }
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Previews
#if !RELEASE
struct TransactionDetailsChartInfoView_Previews: PreviewProvider {
    private static let item1: TransactionTraceabilityModel = .init(items: [
        .full(40),
        .conditional(28),
        .partial(12)
    ])
    private static let item2: TransactionTraceabilityModel = .init(items: [
        .full(40),
        .conditional(28),
        .partial(80),
        .incomplete(40)
    ])

    private static let item3: TransactionTraceabilityModel = .init(items: [
        .full(0),
        .conditional(0),
        .partial(10),
        .incomplete(20)
    ])

    static var previews: some View {
        VStack(spacing: 24) {
            ChartInfoView(pieChartData: item1)
            ChartInfoView(pieChartData: item2)
            ChartInfoView(pieChartData: item3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height)
        .background(.red.opacity(0.5))
    }
}
#endif
