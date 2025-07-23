//
//  LoggedInScreen.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-21.
//

import SwiftUI
import OpenfortSwift

struct LoggedInView: View {
    let email: String
    let onLogout: () -> Void
    private let openfort = OFSDK()
    @State private var showLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 20.0) {
            Text("Welcome, \(email)!")
                .font(.title2)
                .padding()
            Button("Recover Wallet") {
                recoverWallet()
            }
            Button("Logout") {
                showLogoutAlert = true
            }
            .foregroundColor(.red)
            .padding()
        }
        .alert(
            "Log Out",
            isPresented: $showLogoutAlert
        ) {
            Button("Log Out", role: .destructive) {
                logout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private func recoverWallet() {
        openfort.getAccessToken { result in
            switch result {
            case .success(let token):
                let chainId = "80002"
                let configuration = OFConfigureEmbeddedWalletDTO(chainId: chainId, shieldAuthentication: OFShieldAuthenticationDTO(auth: "openfort", token: token.accessToken ?? "" , authProvider: "", tokenType: "accessToken"), recoveryParams: OFRecoveryParamsDTO(recoveryMethod: "automatic", password: nil))
                openfort.configure(params: configuration) { result in
                    switch result {
                    case .success:
                        print("Wallet configured successfully")
                    case .failure(let error):
                        print("Wallet configuration error: \(error)")
                    }
                }
                print("Access token: \(token)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func logout() {
        openfort.logOut { result in
            switch result {
            case .success:
                onLogout()
                break
            case .failure(let error):
                print("Logout error: \(error)")
            }
        }
    }
}
