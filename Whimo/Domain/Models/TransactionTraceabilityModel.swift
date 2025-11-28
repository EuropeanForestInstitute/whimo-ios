//
//  TransactionTraceabilityModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 13.06.2025.
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
import Utility

// MARK: - TransactionTraceabilityModel
struct TransactionTraceabilityModel: DomainModel {
    let items: [Traceability]

    var id: Self { self }
}

// MARK: - Traceability
extension TransactionTraceabilityModel {
    enum Traceability: DomainModel {
        case full(Double)
        case partial(Double)
        case conditional(Double)
        case incomplete(Double)

        var id: Self { self }

        var value: Double {
            switch self {
                case
                    .full(let double),
                    .partial(let double),
                    .conditional(let double),
                    .incomplete(let double):
                double
            }
        }

        var status: TransactionModel.Traceability {
            switch self {
                case .full:
                    .fullTraceability
                case .partial:
                    .partialTraceability
                case .conditional:
                    .conditionalTraceability
                case .incomplete:
                    .incompleteTraceability
            }
        }
    }
}
