//
//  AlertModel+Features.swift
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

import Foundation
import enum Resources.AppLocale

private typealias AlertModel = AlertManager.AlertModel

private typealias Localization = AppLocale.General.Alert

// MARK: - AlertFeatureActionKeys
public protocol AlertFeatureActionKeys: CaseIterable {
    typealias AlertModel = AlertManager.AlertModel

    var button: AlertModel.Button { get }
}

// MARK: - AlertFeature
public protocol AlertFeature {
    typealias ButtonsAxis = AlertManager.AlertModel.ButtonsAxis

    associatedtype ActionKeys: AlertFeatureActionKeys

    static var title: String { get }
    static var subtitle: String? { get }
    static var buttonsAxis: ButtonsAxis { get }
}

extension AlertFeature {
    public static var subtitle: String? { nil }
    public static var buttonsAxis: ButtonsAxis { .horizontal }
    public static var alert: AlertManager.AlertModel {
        .init(
            title: title,
            subtitle: subtitle,
            buttons: buildButtons(),
            buttonsAxis: buttonsAxis
        )
    }

    static func buildButtons() -> [AlertManager.AlertModel.Button] {
        ActionKeys.allCases.map(\.button)
    }
}

// MARK: - Features
extension AlertModel {
    public enum Features {
        public typealias AlertModel = AlertManager.AlertModel
    }
}

extension AlertModel.Features {
    // MARK: - InDevelopment
    public struct InDevelopment: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case ok // swiftlint:disable:this identifier_name

            public var button: AlertModel.Button {
                switch self {
                    case .ok:
                            .init(title: "OK", style: .bordered)
                }
            }
        }

        public static let title: String = "Feature in development"
    }

    // MARK: - Logout
    public struct Logout: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case logout

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.Logout.Button.cancel, style: .bordered)
                    case .logout:
                            .init(title: Localization.Logout.Button.logout)
                }
            }
        }

        public static let title: String = Localization.Logout.title
        public static let subtitle: String? = Localization.Logout.subtitle
    }

    // MARK: - DeleteAccount
    public struct DeleteAccount: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case delete

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.DeleteAccount.Button.cancel, style: .bordered)
                    case .delete:
                            .init(title: Localization.DeleteAccount.Button.delete, style: .destructive)
                }
            }
        }

        public static let title: String = Localization.DeleteAccount.title
        public static let subtitle: String? = Localization.DeleteAccount.subtitle
    }

    // MARK: - SaveTransaction
    public struct SaveTransaction: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case reviewInfo
            case save

            public var button: AlertModel.Button {
                switch self {
                    case .reviewInfo:
                            .init(title: Localization.SaveTransaction.Button.reviewInfo, style: .bordered)
                    case .save:
                            .init(title: Localization.SaveTransaction.Button.save)
                }
            }
        }

        public static let title: String = Localization.SaveTransaction.title
        public static let subtitle: String? = Localization.SaveTransaction.subtitle
        public static var buttonsAxis: ButtonsAxis { .vertical }
    }

    // MARK: - SaveTransaction
    public struct SaveTransactionWithNoLocation: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case save
            case addFarmGeodata

            public var button: AlertModel.Button {
                switch self {
                    case .save:
                            .init(title: Localization.SaveTransactionWithNoLocation.Button.save)
                    case .addFarmGeodata:
                            .init(title: Localization.SaveTransactionWithNoLocation.Button.addFarmGeodata, style: .bordered)
                }
            }
        }

        public static let title: String = Localization.SaveTransactionWithNoLocation.title
        public static let subtitle: String? = Localization.SaveTransactionWithNoLocation.subtitle
        public static var buttonsAxis: ButtonsAxis { .vertical }
    }

    // MARK: - RequestMissingLocation
    public struct RequestMissingLocation: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case request

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.RequestMissingLocation.Button.cancel, style: .bordered)
                    case .request:
                            .init(title: Localization.RequestMissingLocation.Button.request)
                }
            }
        }

        public static let title: String = Localization.RequestMissingLocation.title
        public static let subtitle: String? = Localization.RequestMissingLocation.subtitle
    }

    // MARK: - BuyerExists
    public struct BuyerExists: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case continueInitial
            case continueDownstream

            public var button: AlertModel.Button {
                switch self {
                    case .continueInitial:
                            .init(title: Localization.BuyerExists.Button.continueInitial, style: .bordered)
                    case .continueDownstream:
                            .init(title: Localization.BuyerExists.Button.continueDownstream)
                }
            }
        }

        public static let title: String = Localization.BuyerExists.title
        public static let subtitle: String? = Localization.BuyerExists.subtitle
        public static var buttonsAxis: ButtonsAxis { .vertical }
    }

    // MARK: - EmailAdded
    public struct EmailAdded: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case ok

            public var button: AlertModel.Button {
                switch self {
                    case .ok:
                            .init(title: Localization.EmailAdded.Button.ok)
                }
            }
        }

        public static let title: String = Localization.EmailAdded.title
    }

    // MARK: - PhoneAdded
    public struct PhoneAdded: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case ok

            public var button: AlertModel.Button {
                switch self {
                    case .ok:
                            .init(title: Localization.PhoneAdded.Button.ok)
                }
            }
        }

        public static let title: String = Localization.PhoneAdded.title
    }

    // MARK: - DownloadTxDetails
    public struct DownloadTxDetails: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case download

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.DownloadTxDetails.Button.cancel, style: .bordered)
                    case .download:
                            .init(title: Localization.DownloadTxDetails.Button.download)
                }
            }
        }

        public static let title: String = Localization.DownloadTxDetails.title
    }

    // MARK: - DownloadFarmLocations
    public struct DownloadFarmLocations: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case download

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.DownloadFarmLocations.Button.cancel, style: .bordered)
                    case .download:
                            .init(title: Localization.DownloadFarmLocations.Button.download)
                }
            }
        }

        public static let title: String = Localization.DownloadFarmLocations.title
    }

    // MARK: - DownloadLocations
    public struct DownloadLocations: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case download

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.DownloadLocations.Button.cancel, style: .bordered)
                    case .download:
                            .init(title: Localization.DownloadLocations.Button.download)
                }
            }
        }

        public static let title: String = Localization.DownloadLocations.title
    }

    // MARK: - ContactsPermissionDenied
    public struct ContactsPermissionDenied: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case openSettings

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.ContactsPermissionDenied.Button.cancel, style: .bordered)
                    case .openSettings:
                            .init(title: Localization.ContactsPermissionDenied.Button.openSettings)
                }
            }
        }

        public static let title: String = Localization.ContactsPermissionDenied.title
        public static let subtitle: String? = Localization.ContactsPermissionDenied.subtitle
        public static var buttonsAxis: ButtonsAxis { .vertical }
    }

    // MARK: - ConfirmCommodityConversion
    public struct ConfirmCommodityConversion: AlertFeature {
        public enum ActionKeys: AlertFeatureActionKeys {
            case cancel
            case convert

            public var button: AlertModel.Button {
                switch self {
                    case .cancel:
                            .init(title: Localization.ConfirmCommodityConversion.Button.cancel, style: .bordered)
                    case .convert:
                            .init(title: Localization.ConfirmCommodityConversion.Button.convert)
                }
            }
        }

        public static let title: String = Localization.ConfirmCommodityConversion.title
        public static let subtitle: String? = Localization.ConfirmCommodityConversion.subtitle
        public static var buttonsAxis: ButtonsAxis { .vertical }
    }
}
