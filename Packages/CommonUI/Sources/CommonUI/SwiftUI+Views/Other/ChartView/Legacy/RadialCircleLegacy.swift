//
//  RadialCircleLegacy.swift
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

// MARK: - RadialCircleLegacy
public struct RadialCircleLegacy: Shape {
    public let trimFrom: CGFloat
    public let trimTo: CGFloat
    let thickness: CGFloat
    let spacing: CGFloat

    // MARK: - Public Init
    public init(
        trimFrom: CGFloat,
        trimTo: CGFloat,
        thickness: CGFloat,
        spacing: CGFloat,
    ) {
        self.trimFrom = trimFrom
        self.trimTo = trimTo
        self.thickness = thickness
        self.spacing = spacing
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let outerRadius = radius
        let innerRadius = thickness

        // угловой margin так, чтобы линейный зазор = spacing
        let outerMargin = Angle.radians(Double(spacing) / (2 * .pi * Double(outerRadius)))
        let innerMargin = Angle.radians(Double(spacing) / (2 * .pi * Double(innerRadius)))

        // start and end angles
        let startAngle = Angle(degrees: trimFrom * 360)
        let endAngle   = Angle(degrees: trimTo * 360)
        // скорректированные границы дуг
        let oStart = startAngle + outerMargin
        let oEnd = endAngle - outerMargin
        let iStart = startAngle + innerMargin
        let iEnd = endAngle - innerMargin

        // стартовая точка на внешней дуге
        let startPt = CGPoint(
            x: center.x + outerRadius * cos(CGFloat(oStart.radians)),
            y: center.y + outerRadius * sin(CGFloat(oStart.radians))
        )
        path.move(to: startPt)

        // внешняя дуга
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: oStart,
            endAngle: oEnd,
            clockwise: false
        )

        // соединительная линия к внутренней дуге
        let innerEndPt = CGPoint(
            x: center.x + innerRadius * cos(CGFloat(iEnd.radians)),
            y: center.y + innerRadius * sin(CGFloat(iEnd.radians))
        )
        path.addLine(to: innerEndPt)

        // внутренняя дуга
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: iEnd,
            endAngle: iStart,
            clockwise: true
        )

        // линия обратно к внешней дуге
        let innerStartPt = CGPoint(
            x: center.x + innerRadius * cos(CGFloat(iStart.radians)),
            y: center.y + innerRadius * sin(CGFloat(iStart.radians))
        )
        path.addLine(to: innerStartPt)

        path.closeSubpath()
        return path
    }
}

// MARK: - Previews
#if !RELEASE
struct RadialCircleLegacy_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            ZStack {
                RadialCircleLegacy(
                    trimFrom: 0.0,
                    trimTo: 0.5,
                    thickness: 160,
                    spacing: 0
                )
                .fill(.blue)
                RadialCircleLegacy(
                    trimFrom: 0.505,
                    trimTo: 0.7,
                    thickness: 160,
                    spacing: 0
                )
                .fill(.red)
                RadialCircleLegacy(
                    trimFrom: 0.705,
                    trimTo: 0.995,
                    thickness: 160,
                    spacing: 0
                )
                .fill(.green)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .rotationEffect(.degrees(-90))
    }
}
#endif
