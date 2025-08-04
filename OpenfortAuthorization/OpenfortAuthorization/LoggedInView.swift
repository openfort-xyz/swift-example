//
//  LoggedInScreen.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-21.
//

import SwiftUI
import OpenfortSwift
import FirebaseAuth

struct LoggedInView: View {
    let email: String
    let authProvider : String
    let onLogout: () -> Void
    
    private let openfort = OFSDK.shared
    
    @State private var showLogoutAlert = false
    @State private var embeddedState = 0
    
    var body: some View {
        Group {
            if embeddedState == 4 {
                SignatureView(onSign: { /* action */ }, onLogout: logout)
            } else {
                VStack(spacing: 20.0) {
                    Text("Welcome, \(email)!")
                        .font(.title2)
                        .padding()
                    if embeddedState != 4 {
                        Button("Recover Wallet") {
                            recoverWallet()
                        }
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
        }.onAppear {
            getEmbeddedState()
        }
        
    }
    
    private func getEmbeddedState() {
        openfort.getEmbeddedState { result in
            switch result {
            case .success(let state):
                embeddedState = state
                print("Embedded state: \(state)")
            case .failure(let error):
                print("Failed to get embedded state: \(error.localizedDescription)")
            }
        }
    }
    
    private func recoverWallet() {
        if authProvider == "firebase" {
            processFirebaseRecover()
        } else {
            processOpenfortRecover()
        }
    }
    
    private func processOpenfortRecover() {
        openfort.getAccessToken { result in
            switch result {
            case .success(let token):
                let chainId = 80002
                let configuration = OFConfigureEmbeddedWalletDTO(chainId: chainId, shieldAuthentication: OFShieldAuthenticationDTO(auth: "openfort", token: token , authProvider: "", tokenType: "accessToken"), recoveryParams: OFRecoveryParamsDTO(recoveryMethod: "automatic", password: nil))
                openfort.configure(params: configuration) { result in
                    switch result {
                    case .success:
                        getEmbeddedState()
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
    
    private func processFirebaseRecover() {
        Auth.auth().currentUser?.getIDTokenResult(completion: { result, error in
            if let result = result {
                let token = result.token
                let chainId = 80002
                openfort.configure(params: OFConfigureEmbeddedWalletDTO(chainId: chainId, shieldAuthentication: OFShieldAuthenticationDTO(auth: "openfort", token: token , authProvider: "firebase", tokenType: "idToken"), recoveryParams: OFRecoveryParamsDTO(recoveryMethod: "automatic", password: nil)), completion: { result in
                    switch result {
                    case .success:
                        getEmbeddedState()
                        print("Wallet configured successfully")
                    case .failure(let error):
                        print("Wallet configuration error: \(error)")
                    }
                })
            }
        })
    }
    
    private func logout() {
        if Auth.auth().currentUser != nil {
            try? Auth.auth().signOut()
        }
        
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
