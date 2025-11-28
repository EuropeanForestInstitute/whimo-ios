//
//  NotificationsTarget.swift
//  Whimo
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
//
//  NotificationsTarget.swift
//  Whimo
//
//  Created Vyacheslav Razumeenko on 24.06.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Networking
import RestClient
import Alamofire

public protocol NotificationsTarget {
    func notificationsList(_ model: RequestModels.NotificationsList) async throws -> ResponseModels.NotificationsList
}

extension RequestRouter {
    public enum Notifications {
        case getNotifications(RequestModels.NotificationsList)
    }
}

extension RequestRouter.Notifications: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .getNotifications:
                "/notifications/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .getNotifications:
                .get
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .getNotifications(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .getNotifications:
                true
        }
    }

    public var encoder: ParameterEncoding {
        switch self {
            case .getNotifications:
                FlatURLEncoding.default
        }
    }
}
