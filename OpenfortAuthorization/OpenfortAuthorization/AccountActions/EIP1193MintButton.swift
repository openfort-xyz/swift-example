//
//  EIP1193MintButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct EIP1193MintButton: View {
    let handleSetMessage: (String) -> Void

    @State private var loading: Bool = false
    @State private var loadingBatch: Bool = false
    let openfort: OFSDK

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task { await handleSendTransaction() }
            }) {
                if loading {
                    ProgressView()
                } else {
                    Text("Mint NFT")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != .ready || loading)
            .buttonStyle(.bordered)

            Button(action: {
                Task { await handleSendCalls() }
            }) {
                if loadingBatch {
                    ProgressView()
                } else {
                    Text("Send batch calls")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != .ready || loadingBatch)
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Contract Interaction
    func handleSendTransaction() async {
        loading = true
        defer { loading = false }
        do {
            // --- Your EVM provider logic here ---
            // Example placeholders:
            do {
                let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams())
                handleSetMessage("Provider: \(provider ?? "empty")")
            } catch  {
                handleSetMessage("Failed to get EVM provider")
                return
            }
            
            // Contract and ABI info
            let erc721Address = "0x2522f4fc9af2e1954a3d13f7a5b2683a00a4543a"
            let recipient = "0x64452Dff1180b21dc50033e1680bB64CDd492582"
            // TODO: Build and send transaction using web3 or your EVM SDK
            // Simulate/prepare/send the contract call as in your JS code.
            // If success:
            let txHash = "0xEXAMPLETXHASH"
            handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
            // If error:
            // handleSetMessage("Failed to send transaction: \(error.localizedDescription)")
        }
    }

    func handleSendCalls() async {
        loadingBatch = true
        defer { loadingBatch = false }
        do {
            // --- Your EVM provider logic here ---
            do {
                let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams())
                handleSetMessage("Provider: \(provider ?? "empty")")
            } catch {
                handleSetMessage("Failed to get EVM provider")
                return
            }
            
            let erc721Address = "0x2522f4fc9af2e1954a3d13f7a5b2683a00a4543a"
            let recipient = "0x64452Dff1180b21dc50033e1680bB64CDd492582"
            // TODO: Build and send batch calls using your EVM SDK
            // If success:
            let txHash = "0xEXAMPLETXHASHBATCH"
            handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
        }
    }
}
