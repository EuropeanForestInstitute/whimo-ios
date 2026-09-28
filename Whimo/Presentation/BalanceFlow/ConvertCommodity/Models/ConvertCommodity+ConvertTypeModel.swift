//
//  ConvertCommodity+ConvertTypeModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 03.11.2025.
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

import Foundation

private typealias Module = ConvertCommodityListModule

extension Module {
    struct ConvertTypeModel: Identifiable {
        #if DEBUG || STAGE
        static let roastCoffe: Self = .init(
            id: 1,
            name: "Roast coffee",
            infoText: "Roast your green beans to produce roasted coffee. Some mass is lost and husks are generated as by-products."
        )
        static let decaffeinate: Self = .init(
            id: 2,
            name: "Decaffeinate",
            infoText: "Remove caffeine from green beans to produce decaf coffee and husks as side product."
        )
        static let decaffeinate2: Self = .init(
            id: 4,
            name: "Decaffeinate2",
            infoText: "Remove caffeine from green beans to produce decaf coffee and husks as side product."
        )
        static let decaffeinate3: Self = .init(
            id: 5,
            name: "Decaffeinate3",
            infoText: "Remove caffeine from green beans to produce decaf coffee and husks as side product."
        )
        static let longType: Self = .init(
            id: 3,
            name: "Long Type Long Type Long Type Long Type Long Type",
            infoText: "Remove caffeine from green beans to produce decaf coffee and husks as side product."
        )
        #endif

        let id: Int
        let name: String
        let infoText: String
    }
}
