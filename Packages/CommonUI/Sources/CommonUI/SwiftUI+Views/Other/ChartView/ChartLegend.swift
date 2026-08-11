//
//  ChartLegend.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 14.05.2025.
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
import Charts
import Utility
import Resources
import IdentifiedCollections

// MARK: - ChartLegend
public struct ChartLegend<Model: DomainModel, Value: Numeric & Plottable>: View {
    public typealias Sector = ChartView<Model, Value>.Sector

    private let adaptiveColumn = [
        GridItem(.flexible(minimum: 80, maximum: 1000), spacing: 8),
        GridItem(.flexible(minimum: 80, maximum: 1000), spacing: 8)
    ]

    public let sectors: IdentifiedArrayOf<Sector>

    public init(sectors: IdentifiedArrayOf<Sector>) {
        self.sectors = sectors
    }

    // MARK: - Body
    public var body: some View {
        content()
            .background(AppColors.Other.white.colorSwiftUI)
    }
}

// MARK: - Private Layout
private extension ChartLegend {
    @ViewBuilder func content() -> some View {
        LazyVGrid(columns: adaptiveColumn, alignment: .leading, spacing: 16) {
            ForEach(sectors) { sector in
                itemView(sector: sector)
            }
        }
    }

    @ViewBuilder func itemView(sector: Sector) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(sector.color)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: String(describing: sector.chartValue))
                    .appFontMediumSize12()
                    .foregroundStyle(AppColors.Gray.gray90.colorSwiftUI)
                    .frame(height: 16)
                Text(sector.title)
                    .appFontRegularSize12()
                    .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
                    .frame(height: 16)
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CommonUI_Previews: PreviewProvider {
    private struct TraceabilityModel: DomainModel {
        let status: Status
        let value: Int

        var id: Self { self }
    }

    private enum Status {
        case fullTraceability
        case conditionalTraceability
        case partialTraceability
        case incompleteTraceability

        var title: String { String(describing: self) }

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

    private static let items: IdentifiedArrayOf<TraceabilityModel> = .init(uniqueElements: [
        .init(status: .partialTraceability, value: 40),
        .init(status: .conditionalTraceability, value: 28),
        .init(status: .fullTraceability, value: 12),
    ])

    private static var sectors: IdentifiedArrayOf<ChartView<TraceabilityModel, Int>.Sector> {
        .init(
            uniqueElements: items.map {
                .init(
                    model: $0,
                    title: $0.status.title,
                    chartValue: $0.value,
                    color: $0.status.primaryColor
                )
            }
        )
    }

    static var previews: some View {
        VStack {
            ChartLegend(sectors: sectors)

            ChartLegend(sectors: sectors)
                .frame(width: 168)
        }
        .frame(height: UIScreen.main.bounds.height)
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.5))
        .previewDevice(.iPhone15Pro)
    }
}
#endif
