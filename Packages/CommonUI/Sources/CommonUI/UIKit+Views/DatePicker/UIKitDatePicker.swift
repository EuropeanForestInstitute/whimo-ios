//
//  UIKitDatePicker.swift
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

// MARK: - UIKitDatePicker
public struct UIKitDatePicker: UIViewRepresentable {
    public typealias UIViewType = UIDatePicker
    // MARK: - Properties
    @Binding var startDate: Date

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UIDatePicker {
        let view: UIDatePicker = .init()
        view.datePickerMode = .date
        view.preferredDatePickerStyle = .inline
        view.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.onDateChange(_:)),
            for: .valueChanged
        )

        return view
    }

    public func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = startDate
    }

    public func makeCoordinator() -> Coordinator {
        .init(startDate: $startDate)
    }
}

// MARK: - Coordinator
extension UIKitDatePicker {
    public class Coordinator {
        // MARK: - Properties
        @Binding var startDate: Date

        // MARK: - Init
        public init(startDate: Binding<Date>) {
            self._startDate = startDate
        }

        // MARK: - Methods
        // swiftlint:disable:next strict_fileprivate
        @objc fileprivate func onDateChange(_ sender: UIDatePicker) {
            startDate = sender.date
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct UIKitDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UIKitDatePicker(startDate: .constant(.now))
                .frame(height: 300)
        }
        .previewDevice(.iPhone15Pro)
        .previewDisplayName("Fixed size")

        VStack {
            UIKitDatePicker(startDate: .constant(.now))
        }
        .previewDevice(.iPhone15Pro)
        .previewDisplayName("Full screen")
    }
}
#endif
