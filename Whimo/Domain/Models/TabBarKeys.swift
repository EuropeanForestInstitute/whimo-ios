//
//  TabBarKeys.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 02.05.2025.
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
import typealias Utility.DomainModel

private typealias Localization = AppLocale.TabBar.Tabs

struct TabBarKeys: Identifiable, Hashable {
    // MARK: - Static
    static var home: Self {
        .init(
            id: 0,
            title: Localization.Home.title,
            image: AppAssets.TabBar.tabbarHome.image
        )
    }
    static var balance: Self {
        .init(
            id: 1,
            title: Localization.Balance.title,
            image: AppAssets.TabBar.tabbarBalance.image
        )
    }
    static var settings: Self {
        .init(
            id: 2,
            title: Localization.Settings.title,
            image: AppAssets.TabBar.tabbarSettings.image
        )
    }

    // MARK: - Properties
    var id: Int
    var title: String
    var image: UIImage
    var action: (() -> Void)?

    // MARK: - Public Properties
    func withAction(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.action = action
        return copy
    }

    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
//        lhs.title == rhs.title &&
//        lhs.image == rhs.image

        lhs.id == rhs.id
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(title)
//        hasher.combine(image)
    }
}
