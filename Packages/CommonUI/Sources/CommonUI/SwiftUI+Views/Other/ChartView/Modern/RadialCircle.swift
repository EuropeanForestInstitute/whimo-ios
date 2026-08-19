//
//  RadialCircle.swift
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
import Extensions

// MARK: - RadialCircle
public struct RadialCircle: Shape {
    // MARK: - Public Properties
    public let trimFrom: CGFloat
    public let trimTo: CGFloat
    public let lineWidth: CGFloat
    public let capEdgesCornerRadius: CGFloat

    // MARK: - Public Init
    public init(
        trimFrom: CGFloat,
        trimTo: CGFloat,
        lineWidth: CGFloat,
        capEdgesCornerRadius: CGFloat = 6
    ) {
        self.trimFrom = trimFrom
        self.trimTo = trimTo
        self.lineWidth = lineWidth
        self.capEdgesCornerRadius = capEdgesCornerRadius
    }

    // MARK: - Path
    public func path(in rect: CGRect) -> Path {
        // arc radius
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // start and end angles (-π/2 = top)
        let rawStart = -CGFloat.pi / 2 + 2 * .pi * trimFrom
        let rawEnd   = -CGFloat.pi / 2 + 2 * .pi * trimTo

        let capAngularOffset = capEdgesCornerRadius / radius

        // arc path without rounded caps
        let startAngle = Angle(radians: Double(rawStart + capAngularOffset))
        let endAngle   = Angle(radians: Double(rawEnd - capAngularOffset))
        var arcPath = Path()
        arcPath.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        let strokedArc = arcPath.strokedPath(
            StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
        )

        // compute endpoints of the arc
        let startPoint = CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        )
        let endPoint = CGPoint(
            x: center.x + radius * cos(CGFloat(endAngle.radians)),
            y: center.y + radius * sin(CGFloat(endAngle.radians))
        )

        // define pill cap size
        let capLength = capEdgesCornerRadius * 2
        let capSize = CGSize(width: capLength, height: lineWidth)

        let capRectStart = CGRect(
            origin: CGPoint(
                x: startPoint.x - capLength / 2,
                y: startPoint.y - lineWidth / 2
            ),
            size: capSize
        )
        let capRectEnd = CGRect(
            origin: CGPoint(
                x: endPoint.x - capLength / 2,
                y: endPoint.y - lineWidth / 2
            ),
            size: capSize
        )

        // tangent-based rotation so flat faces align with stroke direction
        let tangentOffset = CGFloat.pi / 2
        let startTangent = CGFloat(startAngle.radians) + tangentOffset
        let endTangent = CGFloat(endAngle.radians) + tangentOffset

        let startTransform = CGAffineTransform.identity
            .translatedBy(x: startPoint.x, y: startPoint.y)
            .rotated(by: startTangent)
            .translatedBy(x: -startPoint.x, y: -startPoint.y)

        let endTransform = CGAffineTransform.identity
            .translatedBy(x: endPoint.x, y: endPoint.y)
            .rotated(by: endTangent)
            .translatedBy(x: -endPoint.x, y: -endPoint.y)

        let capStart = RoundedRectangle(cornerRadius: capEdgesCornerRadius)
            .path(in: capRectStart)
            .applying(startTransform)
        let capEnd = RoundedRectangle(cornerRadius: capEdgesCornerRadius)
            .path(in: capRectEnd)
            .applying(endTransform)

        return strokedArc
            .union(with: capStart)
            .union(with: capEnd)
    }
}

// MARK: - Previews
#if !RELEASE
struct RadialCircle_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ZStack {
                RadialCircle(trimFrom: 0.0, trimTo: 0.5, lineWidth: 20)
                    .fill(.red)
                RadialCircle(trimFrom: 0.505, trimTo: 0.8, lineWidth: 20)
                    .fill(.blue)
                RadialCircle(trimFrom: 0.805, trimTo: 0.995, lineWidth: 20)
                    .fill(.green)
            }

            ZStack {
                RadialCircle(trimFrom: 0.0, trimTo: 0.5, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.red)
                RadialCircle(trimFrom: 0.51, trimTo: 0.8, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.blue)
                RadialCircle(trimFrom: 0.81, trimTo: 0.99, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.green)
            }
            .frame(height: 80)

            ZStack {
                RadialCircle(trimFrom: 0.0, trimTo: 0.05, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.red)
                RadialCircle(trimFrom: 0.06, trimTo: 0.11, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.blue)
                RadialCircle(trimFrom: 0.12, trimTo: 0.8, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.purple)
                RadialCircle(trimFrom: 0.81, trimTo: 0.99, lineWidth: 9, capEdgesCornerRadius: 2)
                    .fill(.green)
            }
            .frame(height: 80)

            ZStack {
                RadialCircle(trimFrom: 0.0, trimTo: 0.05, lineWidth: 30, capEdgesCornerRadius: 2)
                    .fill(.red)
                RadialCircle(trimFrom: 0.06, trimTo: 0.11, lineWidth: 30, capEdgesCornerRadius: 2)
                    .fill(.blue)
                RadialCircle(trimFrom: 0.12, trimTo: 0.8, lineWidth: 30, capEdgesCornerRadius: 2)
                    .fill(.purple)
                RadialCircle(trimFrom: 0.81, trimTo: 0.99, lineWidth: 30, capEdgesCornerRadius: 2)
                    .fill(.green)
            }
            .frame(height: 80)
        }
    }
}
#endif
