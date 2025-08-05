//
//  EIP1193CreateSessionButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct EIP1193CreateSessionButton: View {
    let handleSetMessage: (String) -> Void
    @Binding var sessionKey: String? // 0x-prefixed hex string
    var setSessionKey: (String?) -> Void

    var openfort:OFSDK // Your global Openfort state/model
    @State private var loading = false

    var body: some View {
        VStack {
            Button(action: {
                Task { await handleCreateSession() }
            }) {
                if loading {
                    ProgressView()
                } else {
                    Text("Create session")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != OFEmbeddedState.ready || sessionKey != nil)
            .buttonStyle(.bordered)
            
            BackendMintButton(
                handleSetMessage: handleSetMessage
            )
        }
    }

    func handleCreateSession() async {
        loading = true
        defer { loading = false }
        do {
            do {
                let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams())
            } catch {
                handleSetMessage("Failed to get EVM provider")
                return
            }
            // Generate new private key for session
            let newPrivateKey = generatePrivateKey() // Implement this in Swift
            let sessionAddress = privateKeyToAddress(newPrivateKey) // Implement this

            // Set up wallet client, permissions, etc.
            // -- Place your integration logic here; pseudocode below:

            let granted = try await grantSessionKeyPermissions(
                provider: "provider",
                sessionAddress: sessionAddress,
                contract: "0x2522f4fc9af2e1954a3d13f7a5b2683a00a4543a"
            )
            if granted {
                setSessionKey(newPrivateKey)
                handleSetMessage("""
                Session key registered successfully:
                Address: \(sessionAddress)
                Private Key: \(newPrivateKey)
                """)
            } else {
                handleSetMessage("Failed to register session")
            }
        } catch {
            handleSetMessage("Failed to register session: \(error.localizedDescription)")
        }
    }
}

// Dummy implementations for cryptography (use real library in prod!)
func generatePrivateKey() -> String {
    // Use a secure RNG!
    // Example: generate a random 32-byte hex string prefixed with 0x
    let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
    return "0x" + bytes.map { String(format: "%02x", $0) }.joined()
}

func privateKeyToAddress(_ privateKey: String) -> String {
    // Use web3 or secp256k1 to get the address from private key
    // Here just a dummy example
    return "0x" + privateKey.dropFirst(4).prefix(40)
}

func grantSessionKeyPermissions(provider: Any, sessionAddress: String, contract: String) async throws -> Bool {
    // Implement your EVM permissions logic here
    // Return true if success, false if not
    // For now, always succeed
    return true
}
