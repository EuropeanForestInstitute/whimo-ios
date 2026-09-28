//
//  OverlayDatePicker.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 07.06.2025.
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

// MARK: - OverlayDatePicker
public struct OverlayDatePicker: View {
    // MARK: - Properties
    @Binding var startDate: Date?
    let originY: CGFloat

    // MARK: - Private Properties
    @Environment(\.dismiss) private var dismiss

    public init(startDate: Binding<Date?> = .constant(nil), originY: CGFloat) {
        self._startDate = startDate
        self.originY = originY
    }

    // MARK: - Body
    public var body: some View {
        content()
            .ignoresSafeArea()
            .background {
                Color.white.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
            }
    }
}

// MARK: - Private Layout
private extension OverlayDatePicker {
    @ViewBuilder func content() -> some View {
        GeometryReader { _ in
            VStack {
                datePicker($startDate)
                    .frame(height: 345)
            }
            .offset(y: originY)
            .padding([.horizontal])
        }
    }

    @ViewBuilder func datePicker(_ date: Binding<Date?>) -> some View {
        let binding: Binding<Date> = .init(
            get: { date.wrappedValue ?? .now },
            set: { date.wrappedValue = $0 }
        )

        UIKitDatePicker(startDate: binding)
            .tint(AppColors.Primary.primarySeaBlue.colorSwiftUI)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.Other.white.colorSwiftUI)
                    .shadow(color: AppColors.Gray.gray100.colorSwiftUI.opacity(0.2), radius: 12)
            }
    }
}

// MARK: - Preview
struct OverlayDatePicker_Previews: PreviewProvider {
    struct Container: View {
        @State private var startDate: Date?

        var body: some View {
            OverlayDatePicker(startDate: $startDate, originY: 252)
        }
    }

    static var previews: some View {
        Container()
    }
}
