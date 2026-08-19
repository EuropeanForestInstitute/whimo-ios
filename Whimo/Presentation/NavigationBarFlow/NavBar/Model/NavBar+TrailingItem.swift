//
//  NavBar+TrailingItem.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 06.05.2025.
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

import UIKit
import Resources
import typealias Utility.DomainModel

private typealias Module = NavBarModule
private typealias Assets = AppAssets.Navigation

// MARK: - TrailingItem
extension Module {
    enum TrailingItem: DomainModel {
        case notifications
        case more
        case custom(image: UIImage, alternativeImage: UIImage? = nil, action: () -> Void)

        var id: Self { self }

        var image: UIImage {
            switch self {
                case .notifications:
                    return Assets.navigationNotificationIcon.image
                case .more:
                    return Assets.navigationMoreIcon.image
                case .custom(let image, _, _):
                    return image
            }
        }

        var alternativeImage: UIImage? {
            switch self {
                case .notifications:
                    return Assets.navigationNotificationNewIcon.image
                case .more:
                    return nil
                case .custom(_, let alternativeImage, _):
                    return alternativeImage
            }
        }

        // MARK: - Equatable
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.image == rhs.image
            && lhs.alternativeImage == rhs.alternativeImage
        }

        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(image)
            hasher.combine(alternativeImage)
        }
    }
}
