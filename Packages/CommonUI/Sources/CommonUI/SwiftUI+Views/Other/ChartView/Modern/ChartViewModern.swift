//
//  ChartViewModern.swift
//  CommonUI
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
import Charts
import Utility
import Resources
import IdentifiedCollections

// MARK: - ChartViewModern
@available(iOS 17.0, *)
public struct ChartViewModern<Model: DomainModel, Value: Numeric & Plottable>: View {
    public typealias Sector = ChartView<Model, Value>.Sector

    // MARK: - Public Properties
    public let sectors: IdentifiedArrayOf<Sector>
    public let thickness: CGFloat
    public let cornerRadius: CGFloat
    /// linear clearance in pts
    public let spacing: CGFloat

    // MARK: - Public Init
    public init(
        sectors: IdentifiedArrayOf<Sector>,
        thickness: CGFloat = 0.2,
        cornerRadius: CGFloat = 6,
        spacing: CGFloat
    ) {
        self.sectors = sectors
        self.thickness = thickness
        self.cornerRadius = cornerRadius
        self.spacing = spacing
    }

    // MARK: - Body
    public var body: some View {
        content()
    }
}

// MARK: - Private Layout
@available(iOS 17.0, *)
private extension ChartViewModern {
    @ViewBuilder func content() -> some View {
        VStack {
            Chart {
                ForEach(sectors) { sector in
                    SectorMark(
                        angle: .value(sector.title, sector.chartValue),
                        innerRadius: .fixed(thickness),
                        angularInset: spacing
                    )
                    .foregroundStyle(sector.color)
                    .cornerRadius(cornerRadius)
                }
            }
        }
    }
}

// MARK: - Previews
#if !RELEASE
import typealias Utility.DomainModel
struct ChartViewModern_Previews: PreviewProvider {
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

    @available(iOS 17.0, *)
    private static var sectors: IdentifiedArrayOf<ChartViewModern<TraceabilityModel, Int>.Sector> {
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
                ChartViewModern(
                    sectors: sectors,
                    thickness: 160,
                    cornerRadius: 6,
                    spacing: 2
                )
                .padding(16)

                ChartViewModern(
                    sectors: sectors,
                    thickness: 30,
                    cornerRadius: 2,
                    spacing: 1
                )
                .frame(width: 80, height: 80)
            }
        }
    }
}
#endif
