//
//  UsersTarget.swift
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

import Foundation
import Networking
import RestClient

public protocol UsersTarget {
    func getProfileInfo() async throws -> ResponseModels.ProfileInfo
    func changePassword(_ model: RequestModels.ChangePassword) async throws
    func deleteProfile() async throws
    func checkGadgetExists(_ model: RequestModels.CheckGadgetExists) async throws -> ResponseModels.CheckGadgetExistsInfo
    func addGadget(_ model: RequestModels.AddGadget) async throws
    func deleteGadget(_ model: RequestModels.DeleteGadget) async throws
}

extension RequestRouter {
    public enum Users {
        case getProfileInfo
        case changePassword(RequestModels.ChangePassword)
        case deleteProfile
        case checkGadgetExists(RequestModels.CheckGadgetExists)
        case addGadget(RequestModels.AddGadget)
        case deleteGadget(RequestModels.DeleteGadget)
    }
}

extension RequestRouter.Users: AnyNetworkRouter {
    public var path: Endpoint {
        switch self {
            case .getProfileInfo:
                "/users/profile/"
            case .changePassword:
                "/users/profile/password/"
            case .deleteProfile:
                "/users/profile/delete/"
            case .checkGadgetExists:
                "/users/gadgets/exists/"
            case .addGadget:
                "/users/gadgets/"
            case .deleteGadget:
                "/users/gadgets/"
        }
    }

    public var method: HTTPMethod {
        switch self {
            case .getProfileInfo:
                .get
            case .changePassword:
                .patch
            case .deleteProfile:
                .delete
            case .checkGadgetExists:
                .get
            case .addGadget:
                .post
            case .deleteGadget:
                .delete
        }
    }

    public var parameters: Encodable? {
        switch self {
            case .getProfileInfo, .deleteProfile:
                nil
            case .changePassword(let data):
                data
            case .checkGadgetExists(let data):
                // GET query parameters will be URL-encoded by default encoder
                data
            case .addGadget(let data):
                data
            case .deleteGadget(let data):
                data
        }
    }

    public var addAuth: Bool {
        switch self {
            case .getProfileInfo, .changePassword, .deleteProfile, .checkGadgetExists, .addGadget, .deleteGadget:
                true
        }
    }
}
