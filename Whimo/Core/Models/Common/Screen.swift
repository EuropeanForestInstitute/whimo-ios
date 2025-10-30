//
//  Screen.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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
import CoreLocation
import typealias FlowStacks.Routes
import class FlowStacks.FlowNavigator
import enum StorageKit.KeychainModels
import Utility

typealias AppFlowNavigator = FlowNavigator<Screen>

enum Screen: AnyScreen {
    // system
    case documentPicker(_ didPickData: (_ url: URL) -> Void)
    case openWevView(url: String)

    // auth flow
    case login
    case register
    case changeLanguage
    case forgotPassword
    case createPassword
    case otp(parrentFlow: OTPModule.ParrentFlow, gadgets: NonEmptyArray<UserModel.GadgetModel>)

    // nav bar flow
    case more
    case notificationsList

    // main flow
    case tabBar
    case transactionDetails(transactionId: String)
    case downloadTxDetails(transactionId: String, tradersCount: Int)
    case suppliersHistory(supplierInfo: SuppliersHistoryModule.SupplierInfo)

    // select transaction type flow
    case createTransaction
    case buyTxSelectType
    case buyTxSelectSeller
    case buyTxOnFarmDialog
    case createTransactionForm(transactionType: TransactionType)
    case scanQR
    case chooseFarmGeodata
    case uploadFile(mode: UploadFileModule.Mode)
    case addGpsPoint
    case commoditiesList
    case commodityVolume(volumeAmount: String, commodityType: CommodityGroupModel.Commodity, transactionType: TransactionType)
    case addTransactionRecipient(action: TransactionModel.Action)
    case inviteSeller

    // balance flow
    case groupBalanceDetails(commodityGroup: CommodityGroupModel)

    // settings flow
    case accountInfo
    case gadgetDetails(gadgets: NonEmptyArray<UserModel.GadgetModel>)
    case changePassword
    case notifications
    case changeLanguageFullScreen
}
