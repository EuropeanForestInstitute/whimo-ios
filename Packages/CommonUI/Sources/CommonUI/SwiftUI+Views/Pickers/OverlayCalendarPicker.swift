//
//  OverlayCalendarPicker.swift
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

// MARK: - OverlayCalendarPicker
public struct OverlayCalendarPicker: View {
    // MARK: - Properties
    @Binding var dates: Set<DateComponents>
    let originY: CGFloat

    // MARK: - Private Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    private let datePickerComponents: Set<Calendar.Component> = [.calendar, .era, .year, .month, .day]
    private var datesBinding: Binding<Set<DateComponents>> {
        Binding {
            dates
        } set: { newValue in
            if newValue.isEmpty {
                dates = newValue
            } else if newValue.count > dates.count {
                if newValue.count == 1 {
                    dates = newValue
                } else if newValue.count == 2 {
                    dates = filledRange(selectedDates: newValue)
                } else if let firstMissingDate = newValue.subtracting(dates).first {
                    dates = [firstMissingDate]
                } else {
                    dates = []
                }
            } else if let firstMissingDate = dates.subtracting(newValue).first {
                dates = [firstMissingDate]
            } else {
                dates = []
            }
        }
    }

    // MARK: - Public Init
    public init(dates: Binding<Set<DateComponents>> = .constant([]), originY: CGFloat) {
        self._dates = dates
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
private extension OverlayCalendarPicker {
    @ViewBuilder func content() -> some View {
        GeometryReader { _ in
            VStack {
                datePicker($dates)
                    .frame(height: 345)
            }
            .offset(y: originY)
            .padding([.horizontal])
        }
    }

    @ViewBuilder func datePicker(_ dates: Binding<Set<DateComponents>>) -> some View {
        MultiDatePicker(
            "Select dates",
            selection: datesBinding,
            in: Date(timeIntervalSince1970: Date.timeIntervalSinceReferenceDate)...
        )
        .tint(AppColors.Primary.primarySeaBlue.colorSwiftUI)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.Other.white.colorSwiftUI)
                .shadow(color: AppColors.Gray.gray100.colorSwiftUI.opacity(0.2), radius: 12)
        }
    }
}

// MARK: - Private Methods
private extension OverlayCalendarPicker {
    func filledRange(selectedDates: Set<DateComponents>) -> Set<DateComponents> {
        let allDates = selectedDates.compactMap { calendar.date(from: $0) }
        let sortedDates = allDates.sorted()
        var datesToAdd = [DateComponents]()
        if let first = sortedDates.first, let last = sortedDates.last {
            var date = first
            while date < last {
                if let nextDate = calendar.date(byAdding: .day, value: 1, to: date) {
                    if !sortedDates.contains(nextDate) {
                        let dateComponents = calendar.dateComponents(datePickerComponents, from: nextDate)
                        datesToAdd.append(dateComponents)
                    }
                    date = nextDate
                } else {
                    break
                }
            }
        }
        return selectedDates.union(datesToAdd)
    }
}

// MARK: - Preview
struct OverlayCalendarPicker_Previews: PreviewProvider {
    struct Container: View {
        @State var dates: Set<DateComponents> = []

        var body: some View {
            OverlayCalendarPicker(dates: $dates, originY: 252)
        }
    }

    static var previews: some View {
        Container()
    }
}
