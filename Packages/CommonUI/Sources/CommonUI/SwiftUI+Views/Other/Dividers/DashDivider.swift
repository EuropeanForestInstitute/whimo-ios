//
//  DashDivider.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 29.04.2025.
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

private typealias CurrentView = DashDivider

// MARK: - DashDivider
public struct DashDivider: View {
    // MARK: - Axis
    public enum Axis {
        case vertical
        case horizontal
    }

    // MARK: - Public Properties
    let axis: DashDivider.Axis

    // MARK: - Private Properties

    // MARK: - Init
    public init(axis: DashDivider.Axis = .horizontal) {
        self.axis = axis
    }

    // MARK: - Body
    public var body: some View {
        content()
    }
}

// MARK: - Private Layout
private extension CurrentView {
    @ViewBuilder func content() -> some View {
        switch axis {
            case .horizontal:
                horizontalLine()
            case .vertical:
                verticalLine()
        }
    }

    @ViewBuilder func horizontalLine() -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(height: 1)
            .overlay {
                GeometryReader { proxy in
                    path(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
                        }
                    )
                }
            }
    }

    @ViewBuilder func verticalLine() -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(width: 1)
            .overlay {
                GeometryReader { proxy in
                    path(
                        Path { path in
                            path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                            path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
                        }
                    )
                }
            }
    }

    @ViewBuilder func path(_ path: Path) -> some View {
        path
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundColor(AppColors.Gray.gray20.colorSwiftUI)
    }
}

// MARK: - Previews
#if !RELEASE
struct DashLineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CurrentView(axis: .horizontal)
            Spacer()
                .frame(height: 48)
            CurrentView(axis: .vertical)
            Spacer()
        }
        .padding()
        .previewDevice(.iPhone15Pro)
    }
}
#endif
