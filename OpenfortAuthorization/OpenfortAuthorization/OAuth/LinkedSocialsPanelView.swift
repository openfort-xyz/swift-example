//
//  LinkedSocialsPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-06.
//

import SwiftUI
import OpenfortSwift

struct LinkedSocialsPanelView: View {
    let user: OFUser?
    let handleSetMessage: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linked socials").font(.headline)
            HStack {
                Text("Get user: ").fontWeight(.medium)
                GetUserButton(handleSetMessage: handleSetMessage)
            }
            Text("OAuth methods")
            HStack(spacing: 8) {
                LinkOAuthButton(provider: "google", user: user, handleSetMessage: handleSetMessage)
                    .font(.caption)
                LinkOAuthButton(provider: "twitter", user: user, handleSetMessage: handleSetMessage)
                LinkOAuthButton(provider: "facebook", user: user, handleSetMessage: handleSetMessage)
            }
            Button("Link a Wallet") { handleSetMessage("Link wallet clicked") }
        }
        .cardStyle()
    }
}
