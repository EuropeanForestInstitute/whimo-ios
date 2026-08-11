//
//  DefaultToggleStyle.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 09.05.2025.
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

private typealias DefaultToggleStyle = Style.Toggle.DefaultToggleStyle
private typealias Theme = DefaultToggleStyle.Theme

extension Style.Toggle {
    // MARK: - DefaultToggleStyle
    public struct DefaultToggleStyle: ToggleStyle {
        // MARK: Constants
        private enum Constants {
            static let toggleWidth: CGFloat = 44
            static let toggleHeight: CGFloat = 24
            static let cornerRadius: CGFloat = 14
            static let thumbDiameter: CGFloat = 20
        }

        let colorModel: Theme

        public init(colorModel: Theme) {
            self.colorModel = colorModel
        }

        public func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                Spacer()
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .circular)
                    .fill(configuration.isOn ? colorModel.onColor : colorModel.offColor)
                    .frame(width: Constants.toggleWidth, height: Constants.toggleHeight)
                    .overlay(
                        Circle()
                            .fill(colorModel.thumbColor)
                            .shadow(radius: 1, x: 0, y: 1)
                            .padding(1)
                            .frame(width: Constants.thumbDiameter, height: Constants.thumbDiameter)
                            .offset(x: configuration.isOn ? Constants.thumbDiameter / 2 : -Constants.thumbDiameter / 2)
                    )
                    .animation(Animation.easeInOut(duration: 0.2), value: configuration.isOn)
                    .onTapGesture { configuration.isOn.toggle() }
            }
            .font(.title)
        }
    }
}

// MARK: - Theme
extension DefaultToggleStyle {
    public struct Theme: Equatable {
        let onColor: Color
        let offColor: Color
        let thumbColor: Color
    }
}

// MARK: - Theme+ThemeList
extension Theme {
    public static var standard: Self {
        .init(
            onColor: AppColors.Primary.primarySeaBlue.colorSwiftUI,
            offColor: AppColors.Gray.gray10.colorSwiftUI,
            thumbColor: AppColors.Other.white.colorSwiftUI
        )
    }
}

// MARK: - Toggle+DefaultToggleStyle
extension Toggle {
    public func applyDefaultAppearance() -> some View {
        toggleStyle(Style.Toggle.DefaultToggleStyle(colorModel: .standard))
    }
}

// MARK: - Previews
#if !RELEASE
struct AppToggle_Previews: PreviewProvider {
    class State: ObservableObject {
        @Published var isOn = false
    }

    struct Container: View {
        @StateObject var state: State = .init()

        var body: some View {
            VStack(spacing: 32) {
                Toggle("", isOn: $state.isOn)

                Toggle("", isOn: $state.isOn)
                    .applyDefaultAppearance()
            }
        }
    }

    static var previews: some View {
        VStack {
            Container()
                .frame(width: 100)
        }
        .previewDevice(.iPhone15Pro)
    }
}
#endif
