//
//  ChartViewLegacy.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 15.05.2025.
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

// MARK: - ChartViewLegacy
public struct ChartViewLegacy<Model: DomainModel, Value: Numeric & Plottable>: View {
    public typealias Sector = ChartView<Model, Value>.Sector

    public let sectors: IdentifiedArrayOf<Sector>
    let thickness: CGFloat
    /// linear clearance in pts
    let spacing: CGFloat

    // MARK: - Private Properties
    private var chartTotalValue: Value {
        sectors.reduce(into: .zero) { partialResult, sector in
            partialResult += sector.chartValue
        }
    }

    public init(
        sectors: IdentifiedArrayOf<Sector>,
        thickness: CGFloat,
        spacing: CGFloat
    ) {
        self.sectors = sectors
        self.thickness = thickness
        self.spacing = spacing
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sectors) { sector in
                    RadialCircleLegacy(
                        trimFrom: from(sector),
                        trimTo: to(sector),
                        thickness: thickness,
                        spacing: spacing
                    )
                    .fill(sector.color)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .rotationEffect(.degrees(-90))
    }
}

// MARK: - Private Methods
private extension ChartViewLegacy {
    func sectorPercetnage(_ sector: Sector) -> CGFloat {
        let value: CGFloat
        switch (sector.chartValue, chartTotalValue) {
            case (let chartValue as Int, let chartTotalValue as Int):
                value = CGFloat(chartValue) / CGFloat(chartTotalValue)
            case (let chartValue as CGFloat, let chartTotalValue as CGFloat):
                value = chartValue / chartTotalValue
            default:
                value = .zero
                log.error("Unsupported chart value type: \(Value.self)")
        }
        return value
    }

    func from(_ sector: Sector) -> CGFloat {
        let sectorIndex = sectors.firstIndex(of: sector) ?? .zero
        let previousSectors = sectors.prefix(upTo: sectorIndex)
        var percetnage: CGFloat = .zero
        for sector in previousSectors {
            let sectorPercetnage = sectorPercetnage(sector)
            percetnage += sectorPercetnage
        }

        return percetnage
    }

    func to(_ sector: Sector) -> CGFloat {
        from(sector) + sectorPercetnage(sector)
    }
}

// MARK: - Previews
#if !RELEASE
struct ChartViewLegacy_Previews: PreviewProvider {
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

    private static var sectors: IdentifiedArrayOf<ChartViewLegacy<TraceabilityModel, Int>.Sector> {
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
            if #available(iOS 17.0, *) {
                ChartViewLegacy(
                    sectors: sectors,
                    thickness: 50,
                    spacing: 12
                )
            }
        }
        .padding()
    }
}
#endif
