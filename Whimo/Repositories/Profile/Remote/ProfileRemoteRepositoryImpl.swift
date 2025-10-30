//
//  ProfileRemoteRepositoryImpl.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 24.06.2025.
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
import RestClient
import Targets
import Utility

final class ProfileRemoteRepositoryImpl: ProfileRemoteRepository {
    // MARK: - Dependencies
    private let usersTarget: UsersTarget
    private let userMapper: UserMapperProtocol

    // MARK: - Init
    init(
        usersTarget: UsersTarget,
        userMapper: UserMapperProtocol
    ) {
        self.usersTarget = usersTarget
        self.userMapper = userMapper
    }

    // MARK: - ProfileRemoteRepository
    func fetchProfile() async throws -> UserModel {
        let response = try await usersTarget.getProfileInfo()
        let userModel = userMapper.toDomain(dto: response.data)

        return userModel
    }

    func checkGadgetExists(_ identifier: String) async throws -> Bool {
        let request: RequestModels.CheckGadgetExists = .init(identifier: identifier)
        let response = try await self.usersTarget.checkGadgetExists(request)
        return response.data.exists
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let request: RequestModels.ChangePassword = .init(currentPassword: currentPassword, newPassword: newPassword)
        try await usersTarget.changePassword(request)
    }

    func deleteProfile() async throws {
        try await usersTarget.deleteProfile()
    }

    func addGadget(gadget: UserModel.GadgetModel) async throws {
        let request: RequestModels.AddGadget
        switch gadget.type {
            case .email:
                request = .init(email: gadget.identifier)
            case .phone:
                request = .init(phone: gadget.identifier)
        }
        try await usersTarget.addGadget(request)
    }

    func changeGadget(newGadget: UserModel.GadgetModel, oldGadget: UserModel.GadgetModel) async throws {
        log.debug("Changing gadget from \(oldGadget.identifier) to \(newGadget.identifier)")

        // Step 1: Delete old gadget
        let deleteRequest: RequestModels.DeleteGadget = .init(identifier: oldGadget.identifier)
        try await usersTarget.deleteGadget(deleteRequest)
        log.debug("Old gadget deleted successfully")

        // Step 2: Add new gadget
        let addRequest: RequestModels.AddGadget
        switch newGadget.type {
            case .email:
                addRequest = .init(email: newGadget.identifier)
            case .phone:
                addRequest = .init(phone: newGadget.identifier)
        }
        try await usersTarget.addGadget(addRequest)
        log.debug("New gadget added successfully")
    }
}
