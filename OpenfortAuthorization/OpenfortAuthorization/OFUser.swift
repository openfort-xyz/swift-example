//
//  OFUser.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-23.
//

import OpenfortSwift


final class OFUser {
    static let shared = OFUser()
    private init() {}

    var token: String?
    var refreshToken: String?
    var player: OFPlayerInfo?
    var action: String?
    var details: OFAuthorizationResponse.ActionDetails?

    func update(from response: OFAuthorizationResponseProtocol) {
        self.token = response.token
        self.refreshToken = response.refreshToken
        self.player = response.player
        self.action = response.action
        self.details = response.details
    }

    func clear() {
        self.token = nil
        self.refreshToken = nil
        self.player = nil
        self.action = nil
        self.details = nil
    }
}
