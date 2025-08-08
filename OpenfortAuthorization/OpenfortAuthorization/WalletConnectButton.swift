//
//  WalletConnectButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-08.
//

import SwiftUI
import OpenfortSwift

struct WalletConnectorInfo: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let type: WalletConnector
}

enum WalletConnector: String, CaseIterable, Identifiable {
    case metamask, coinbase, walletconnect
    var id: String { rawValue }
}

// Dummy icons, replace with your own
let availableWallets: [WalletConnectorInfo] = [
    .init(id: "metamask", name: "MetaMask", iconName: "cube.box", type: .metamask),
    .init(id: "coinbase", name: "Coinbase", iconName: "wallet.pass", type: .coinbase),
    .init(id: "walletconnect", name: "WalletConnect", iconName: "link", type: .walletconnect)
]

// This would be your main buttons section
struct WalletConnectButtonsSection: View {
    @State private var loadingButtonId: String? = nil
    let onSuccess: () -> Void
    let link: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(availableWallets) { wallet in
                WalletConnectButton(
                    title: wallet.name,
                    isLoading: loadingButtonId == wallet.id,
                    iconName: wallet.iconName,
                    onTap: { connect(wallet: wallet) }
                )
            }
        }
    }

    // This is where the SIWE & wallet logic would go!
    func connect(wallet: WalletConnectorInfo) {
        loadingButtonId = wallet.id
        Task {
            do {
                // 1. Initiate wallet connection (show QR, deeplink, etc.)
                let address = try await connectToWallet(wallet.type)
                // 2. Get nonce from backend (openfort)
                let nonce = try await fetchNonce(address: address)
                // 3. Create SIWE message
                let siweMessage = createSIWEMessage(address: address, nonce: nonce, chainId: 80001)
                // 4. Request signature from wallet
                let signature = try await signMessage(siweMessage, with: wallet.type)
                // 5. Authenticate or link with backend
                try await authenticateOrLink(signature: signature, message: siweMessage, wallet: wallet, link: link)
                onSuccess()
            } catch {
                // Show error, e.g. with a toast
            }
            loadingButtonId = nil
        }
    }
}

struct WalletConnectButton: View {
    let title: String
    let isLoading: Bool
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: iconName)
                }
                Text(title)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Helper/Network Logic Stubs
func connectToWallet(_ type: WalletConnector) async throws -> String {
    // Integrate with WalletConnect, MetaMask, etc.
    // Return user's Ethereum address
    throw NSError(domain: "stub", code: -1)
}

func fetchNonce(address: String) async throws -> String {
    let result =  try await OFSDK.shared.initSIWE(params: OFInitSIWEParams(address: address))
    return result?.nonce ?? ""
}

func createSIWEMessage(address: String, nonce: String, chainId: Int) -> String {
    SIWEUtils.createSIWEMessage(address: address, nonce: nonce, chainId: chainId)
}

func signMessage(_ message: String, with wallet: WalletConnector) async throws -> String {
    let result = try await OFSDK.shared.signMessage(params: OFSignMessageParams(message: message))
    return result ?? ""
    
}

func authenticateOrLink(signature: String, message: String, wallet: WalletConnectorInfo, link: Bool) async throws {
    if link {
        _ = try await OFSDK.shared.linkWallet(params: OFLinkWalletParams(signature: signature, message: message, walletClientType: wallet.name, connectorType: wallet.type.rawValue, authToken: try OFSDK.shared.getAccessToken() ?? ""))
    } else {
        _ = try await OFSDK.shared.authenticateWithSIWE(params: OFAuthenticateWithSIWEParams(signature: signature, message: message, walletClientType: wallet.name, connectorType: wallet.type.rawValue))
    }
}
