//
//  ChartView.swift
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
import IdentifiedCollections

// MARK: - ChartView
public struct ChartView<Model: DomainModel, Value: Numeric & Plottable>: View {
    // MARK: - Sector
    public struct Sector: DomainModel {
        let model: Model
        let title: String
        let chartValue: Value
        let color: Color

        public init(model: Model, title: String, chartValue: Value, color: Color) {
            self.model = model
            self.title = title
            self.chartValue = chartValue
            self.color = color
        }

        public var id: Self { self }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(model.hashValue)
        }
    }

    // MARK: - Public Properties
    public let sectors: IdentifiedArrayOf<Sector>
    public let thickness: CGFloat
    /// Corner radius can be appied only for iOS17 and abowe.
    /// For iOS16 this property will be ignored.
    /// This value doesn't affect on legacy side of this view.
    public let cornerRadius: CGFloat
    /// Linear clearance in pts
    public let spacing: CGFloat

    // MARK: - Public Init
    /// - Parameters:
    ///   - sectors: input data
    ///   - thickness: thickness of sectors
    ///   - cornerRadius: corner radius of sectors.
    /// Corner radius can be appied only for iOS17 and abowe.
    /// For iOS16 this property will be ignored.
    /// This value doesn't affect on legacy side of this view.
    ///
    ///   - spacing: spacing between sector
    public init(
        sectors: IdentifiedArrayOf<Sector>,
        thickness: CGFloat = 20,
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
private extension ChartView {
    @ViewBuilder func content() -> some View {
        if #available(iOS 17.0, *) {
            ChartViewModern(
                sectors: sectors,
                thickness: thickness,
                cornerRadius: cornerRadius,
                spacing: spacing
            )
        } else {
            ChartViewLegacy(
                sectors: sectors,
                thickness: thickness,
                spacing: spacing
            )
        }
    }
}

// MARK: - Previews
#if !RELEASE
import typealias Utility.DomainModel
import Resources

struct ChartView_Previews: PreviewProvider {
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
//            ChartView(
//                sectors: sectors,
//                thickness: 160,
//                spacing: 10
//            )
//            .padding(16)

            if #available(iOS 17.0, *) {
                ChartViewModern(
                    sectors: sectors,
                    thickness: 160,
                    cornerRadius: 0,
                    spacing: 10
                )
                .padding(16)
            }

            ChartViewLegacy(
                sectors: sectors,
                thickness: 160,
                spacing: 50
            )
            .padding(16)
        }
    }
}
#endif
