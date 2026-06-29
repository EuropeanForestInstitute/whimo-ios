//
//  UIKitCalendarPicker.swift
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
import Utility

// MARK: - UIKitCalendarPicker
public struct UIKitCalendarPicker: UIViewRepresentable {
    public typealias UIViewType = UICalendarView
    // MARK: - Properties
    @Binding var startDate: Date

    // MARK: - UIViewRepresentable
    public func makeUIView(context: Context) -> UICalendarView {
        let multiSelect = UICalendarSelectionMultiDate(delegate: context.coordinator)
        let view: UICalendarView = .init()

        view.calendar = .init(identifier: .gregorian)
        view.selectionBehavior = multiSelect

        return view
    }

    public func updateUIView(_ uiView: UICalendarView, context: Context) { }

    public func makeCoordinator() -> Coordinator {
        .init(startDate: $startDate)
    }
}

// MARK: - Coordinator
extension UIKitCalendarPicker {
    public class Coordinator: NSObject {
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

extension UIKitCalendarPicker.Coordinator: UICalendarSelectionMultiDateDelegate {
    public func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
        log.debug("\(dateComponents)")
    }

    public func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
        log.debug("\(dateComponents)")
    }
}

// MARK: - Previews
#if !RELEASE
struct UIKitCalendarPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UIKitCalendarPicker(startDate: .constant(.now))
                .frame(height: 300)
        }
        .previewDevice(.iPhone15Pro)
        .previewDisplayName("Fixed size")

        VStack {
            UIKitCalendarPicker(startDate: .constant(.now))
        }
        .previewDevice(.iPhone15Pro)
        .previewDisplayName("Full screen")
    }
}
#endif
