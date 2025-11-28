//
//  OTPField.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 01.05.2025.
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
import Combine
import Resources

// MARK: - OTPField
public struct OTPField: View {
    private enum Constants {
        static let nullCharacter = "\u{200B}"
    }

    // MARK: - Properties
    let lenght: UInt8
    @Binding var otp: String

    // MARK: - Private Properties
    @State private var otpArray: [String]
    @State private var oldOtpArray: [String]
    @FocusState private var fieldFocus: Int?

    // MARK: - Init
    public init(lenght: UInt8 = 4, otp: Binding<String>) {
        self.lenght = lenght
        self._otp = .init(projectedValue: otp)
        self.otpArray = .init(repeating: Constants.nullCharacter, count: Int(lenght))
        self.oldOtpArray = .init(repeating: Constants.nullCharacter, count: Int(lenght))
    }

    // MARK: - Body
    public var body: some View {
        content()
            .onReceive(
                Just(otpArray)
                    .map { $0.joined().trimmingCharacters(in: .whitespaces) }
                    .removeDuplicates()
            ) { otp in
                self.otp = otp
            }
    }
}

// MARK: - Private Layout
private extension OTPField {
    @ViewBuilder func content() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<Int(lenght), id: \.self) { index in
                codeRow(index: index)
            }
        }
    }

    @ViewBuilder func codeRow(index: Int) -> some View {
        AppTextField(
            description: "",
            font: FontBuilder.buildSemibold(size: 22),
            backgroundColor: AppColors.Other.white.colorSwiftUI,
            text: $otpArray[index]
        )
        .multilineTextAlignment(.center)
        .frame(width: 48)
        .keyboardType(.numberPad)
        .focused($fieldFocus, equals: index)
        .tag(index)
        .onChange(of: otpArray[index]) { [oldValue = otpArray[index]] newValue in
            self.oldOtpArray[index] = oldValue

            if newValue.isEmpty {
                // dont needs to switch to previous number if number deleted from current field
                if Int(oldValue) != nil {
                    return
                }

                fieldFocus = max(.zero, (fieldFocus ?? .zero) - 1)
            } else if newValue != Constants.nullCharacter {
                fieldFocus = (fieldFocus ?? .zero) + 1
            }
        }
        .onReceive(Just(otpArray[index])) { newValue in
            let result = limitText(newValue, upper: 1)
            self.otpArray[index] = result

            if newValue.isEmpty, Int(oldOtpArray[index]) == nil {
                let prevIndex = max(.zero, index - 1)
                Task {
                    self.otpArray[prevIndex] = result
                }
            }
        }
    }

    func limitText(_ text: String, upper: Int) -> String {
        if text.count > upper {
            if let first = text.first, "\(first)" == Constants.nullCharacter {
                return String(text.suffix(upper))
            }
            return String(text.prefix(upper))
        }
        if text.isEmpty {
            return Constants.nullCharacter
        }
        return text
    }
}

// MARK: - Previews
#if !RELEASE
struct OTPField_Previews: PreviewProvider {
    private struct Container: View {
        @State private var otp: String = ""

        var body: some View {
            OTPField(otp: $otp)
        }
    }

    static var previews: some View {
        VStack {
            Container()
        }
        .padding()
        .previewDevice(.iPhone15Pro)
    }
}
#endif
