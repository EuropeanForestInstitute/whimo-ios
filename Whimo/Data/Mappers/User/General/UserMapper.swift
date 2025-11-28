//
//  UserMapper.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 23.05.2025.
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
import DatabaseKit
import RestClient

struct UserMapper: UserMapperProtocol {
    // MARK: - DTO -> Domain
    private func toDomain(
        _ gadgets: [ResponseModels.Profile.Gadget]
    ) -> [UserModel.GadgetModel] {
        gadgets.map {
            UserModel.GadgetModel(
                identifier: $0.identifier,
                type: toDomain($0.type),
                isVerified: $0.isVerified
            )
        }
    }

    private func toDomain(
        _ gadgetType: ResponseModels.Profile.Gadget.GadgetType
    ) -> UserModel.GadgetModel.GadgetType {
        switch gadgetType {
            case .email:
                .email
            case .phone:
                .phone
        }
    }

    func toDomainOptional(dto: ResponseModels.Profile?) -> UserModel? {
        if let dto {
            return .init(
                id: dto.id,
                username: dto.username,
                gadgets: toDomain(dto.gadgets)
            )
        }

        return nil
    }

    func toDomain(dto: ResponseModels.Profile) -> UserModel {
        .init(
            id: dto.id,
            username: dto.username,
            gadgets: toDomain(dto.gadgets)
        )
    }

    // MARK: - Database -> Domain
    private func toDomain(from dbModel: DatabaseKit.User.Gadget.GadgetType) -> UserModel.GadgetModel.GadgetType {
        switch dbModel {
            case .email:
                .email
            case .phone:
                .phone
        }
    }

    func toDomain(from dbModel: DatabaseKit.User) -> UserModel {
        let gadgets: [UserModel.GadgetModel] = dbModel.gadgets.map { gadget in
                .init(
                    identifier: gadget.identifier,
                    type: toDomain(from: gadget.type),
                    isVerified: gadget.isVerified
                )
        }

        return .init(
            id: dbModel.id,
            username: dbModel.username,
            gadgets: gadgets
        )
    }

    func toDomain(from dbModel: DatabaseKit.User?) -> UserModel? {
        if let dbModel {
            let model: UserModel = toDomain(from: dbModel)
            return model
        }

        return nil
    }

    // MARK: - Domain -> Database
    private func toDatabase(from dModel: UserModel.GadgetModel.GadgetType) -> DatabaseKit.User.Gadget.GadgetType {
        switch dModel {
            case .email:
                .email
            case .phone:
                .phone
        }
    }

    private func toDatabase(from dModel: UserModel.GadgetModel) -> DatabaseKit.User.Gadget {
        .init(
            id: dModel.id,
            identifier: dModel.identifier,
            type: toDatabase(from: dModel.type),
            isVerified: dModel.isVerified
        )
    }

    func toDatabase(from dModel: UserModel?) -> DatabaseKit.User? {
        if let dModel {
            return .init(
                id: dModel.id,
                username: dModel.username,
                gadgets: dModel.gadgets.map(toDatabase)
            )
        }

        return nil
    }
}
