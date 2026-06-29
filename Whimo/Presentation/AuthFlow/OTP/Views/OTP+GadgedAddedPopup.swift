//
//  OTP+GadgedAddedPopup.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 27.08.2025.
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
import CommonUI
import Resources
import Extensions

private typealias Module = OTPModule
private typealias GadgedAddedPopup = Module.GadgedAddedPopup
private typealias Localization = AppLocale.General.Alert

// MARK: - GadgedAddedPopup
extension Module {
    struct GadgedAddedPopup: View {
        // MARK: - Gadget
        struct Gadget {
            let identifier: String
            let type: UserModel.GadgetModel.GadgetType

            private init(identifier: String, type: UserModel.GadgetModel.GadgetType) {
                self.identifier = identifier
                self.type = type
            }

            static func email(identifier: String) -> Self {
                self.init(identifier: identifier, type: .email)
            }

            static func phone(identifier: String) -> Self {
                self.init(identifier: identifier, type: .phone)
            }

            var title: AttributedString {
                switch type {
                    case .email:
                        var title: AttributedString = .init(Localization.EmailAdded.subtitle(identifier))
                        title.replacingOccurrences(
                            of: identifier,
                            with: .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )

                        return title
                    case .phone:
                        var title: AttributedString = .init(Localization.PhoneAdded.subtitle(identifier))
                        title.replacingOccurrences(
                            of: identifier,
                            with: .init([
                                .font: AppFonts.FiraSans.medium.font(size: 16),
                                .foregroundColor: AppColors.Gray.gray90.color
                            ])
                        )

                        return title
                }
            }
        }

        // MARK: - Public Properties
        let gadget: Gadget

        // MARK: - Init

        // MARK: - Body
        var body: some View {
            content()
                .background()
        }
    }
}

// MARK: - Private Layout
private extension GadgedAddedPopup {
    @ViewBuilder func content() -> some View {
        Text(gadget.title)
            .appFontRegularSize16()
            .foregroundStyle(AppColors.Gray.gray60.colorSwiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
    }
}

// MARK: - Previews
#if !RELEASE
struct OTPGadgedAddedPopup_Previews: PreviewProvider {
    private static let emailGadget: Module.GadgedAddedPopup.Gadget = .email(identifier: "example@example.com")
    private static let phoneGadget: Module.GadgedAddedPopup.Gadget = .phone(identifier: "+1234567890")

    static var previews: some View {
        VStack(spacing: 32) {
            Spacer()
            GadgedAddedPopup(gadget: emailGadget)
            GadgedAddedPopup(gadget: phoneGadget)
            Spacer()
        }
        .background(.red)
    }
}
#endif
