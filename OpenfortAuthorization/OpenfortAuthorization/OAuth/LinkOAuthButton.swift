//
//  LinkOAuthButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-06.
//

import SwiftUI
import OpenfortSwift

struct LinkOAuthButton: View {
    let provider: String
    let user: OFGetUserInstanceResponse?
    @State private var isLoading = false
    
    // Closure for navigation to url, replace with your navigation logic if needed
    var handleSetMessage: ((String) -> Void)? = nil

    var isLinked: Bool {
        guard let user = user, let linkedAccounts = user.linkedAccounts else { return false }
        return linkedAccounts.contains(where: { $0.provider == provider })
    }

    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await linkOAuth()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("\(isLinked ? "Linked" : "Link") \(provider.capitalized)")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(isLinked)
        }
        .padding(.vertical, 6)
    }
    
    @MainActor
    private func linkOAuth() async {
        guard !isLinked else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            // Get access token from Openfort SDK
            let accessToken = try await OFSDK.shared.getAccessToken()
            // Prepare redirect URL
            let redirectTo = "http://localhost:5173/login" // Replace with your actual redirect URL

            // Call SDK's link OAuth method
            let response = try await OFSDK.shared.initLinkOAuth(params: OFInitLinkOAuthParams(provider: provider, authToken: accessToken ?? "", options: ["redirectTo": AnyCodable(redirectTo)]))
            
            // Open the returned URL (SwiftUI way)
            if let urlString = response?.url, let url = URL(string: urlString) {
                await UIApplication.shared.open(url)
            }
        } catch {
            print("Failed to link OAuth:", error)
            handleSetMessage?("Failed to link \(provider). Please try again.")
        }
    }
}
