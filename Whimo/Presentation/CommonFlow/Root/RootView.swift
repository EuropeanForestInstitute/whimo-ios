//
//  RootView.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 29.04.2025.
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

private typealias Module = RootModule
private typealias ModuleView = Module.MainView

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Private Properties
        private var isLoading: Binding<Bool> {
            .init {
                viewModel.isLoading
            } set: { _ in
                ()
            }
        }

        // MARK: - Dependencies
        @StateObject var viewModel: ViewModel = .init()

        // MARK: - Init

        // MARK: - Body
        var body: some View {
            ZStack {
                AppColors.Other.white.colorSwiftUI
                    .ignoresSafeArea()
                content()
            }
            .installLoaderView(isEnable: isLoading)
        }
    }
}

// MARK: - Private Layout
private extension ModuleView {
    @ViewBuilder func content() -> some View {
        CoordinatorModule.assemble(navigationHandler: viewModel.navigationHandler) { screen, _ in
            switch screen {
                // system
                case .documentPicker(let didPickData):
                    DocumentPicker(didPickData: didPickData)
                case .openWevView(let url):
                    WebView(stringURL: url)
                // auth flow
                case .login:
                    LoginModule.assemble()
                case .register:
                    RegisterModule.assemble()
                case .changeLanguage:
                    VStack(spacing: .zero) {
                        Spacer()
                            .frame(height: 16)
                        ChangeLanguageModule.assemble()
                    }
                    .selfSizedSheet()
                    .background { OverridingBackgroundView() }
                case .forgotPassword:
                    ForgotPasswordModule.assemble()
                case .createPassword:
                    CreatePasswordModule.assemble()
                case .otp(let parrentFlow, let gadgets):
                    OTPModule.assemble(parrentFlow: parrentFlow, gadgets: gadgets)
                // nav bar flow
                case .more:
                    MoreModule.assemble()
                        .selfSizedSheet()
                        .background { OverridingBackgroundView() }
                case .notificationsList:
                    NotificationsListModule.assemble()
                // main flow
                case .tabBar:
                    TabBarModule.assemble()
                case .transactionDetails(let transactionId):
                    TransactionDetailsModule.assemble(transactionId: transactionId)
                case .downloadTxDetails(let transactionId, let tradersCount):
                    DownloadTxDetailsModule.assemble(transactionId: transactionId, tradersCount: tradersCount)
                        .selfSizedSheet()
                        .background { OverridingBackgroundView() }
                case .suppliersHistory(let supplierInfo):
                    SuppliersHistoryModule.assemble(supplierInfo: supplierInfo)
                // select transaction type flow
                case .createTransaction:
                    CreateTxSelectTypeModule.assemble()
                case .buyTxSelectType:
                    BuyTxSelectTypeModule.assemble()
                case .buyTxSelectSeller:
                    BuyTxSelectSellerModule.assemble()
                case .buyTxOnFarmDialog:
                    BuyTxOnFarmDialogModule.assemble()
                case .createTransactionForm(let transactionType):
                    CreateTransactionFormModule.assemble(transactionType: transactionType)
                case .scanQR:
                    ScanQRModule.assemble()
                case .chooseFarmGeodata:
                    ChooseFarmGeodataModule.assemble()
                case .uploadFile(let mode):
                    UploadFileModule.assemble(mode: mode)
                case .addGpsPoint:
                    AddGpsPointModule.assemble()
                case .commoditiesList:
                    CommoditiesListModule.assemble()
                case .commodityVolume(let volumeAmount, let commodityType, let transactionType):
                    CommodityVolumeModule.assemble(
                        volumeAmount: volumeAmount,
                        commodityType: commodityType,
                        transactionType: transactionType
                    )
                case .addTransactionRecipient(let action):
                    AddTransactionRecipientModule.assemble(action: action)
                case .inviteSeller:
                    InviteSellerModule.assemble()
                // balance flow
                case .groupBalanceDetails(let commodityGroup):
                    BalanceGroupDetailsModule.assemble(model: commodityGroup)
                case .convertCommodityList(let commodity):
                    ConvertCommodityListModule.assemble(commodity: commodity)
                case .convertCommodityDetails(let commodity, let convertionRule):
                    ConvertCommodityDetailsModule.assemble(commodity: commodity, convertionRule: convertionRule)
                // settings flow
                case .accountInfo:
                    AccountInfoModule.assemble()
                case .gadgetDetails(let gadgets):
                    GadgetDetailsModule.assemble(gadgets: gadgets)
                case .changePassword:
                    ChangePasswordModule.assemble()
                case .notifications:
                    NotificationsModule.assemble()
                case .changeLanguageFullScreen:
                    VStack {
                        ChangeLanguageModule.assemble(showBackButton: true)
                        Spacer()
                    }
                    .background {
                        AppColors.Gray.gray5.colorSwiftUI
                            .ignoresSafeArea()
                    }
            }
        }
    }
}

// MARK: - Private Methods
private extension ModuleView { }

// MARK: - Previews
#if !RELEASE
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootModule.assemble()
    }
}
#endif
