//
//  BackendMintButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct BackendMintButton: View {
    let handleSetMessage: (String) -> Void

    @State private var isLoading: Bool = false
    @State private var stateIsReady: Bool = true // Set from your environment/model

    var body: some View {
        Button(action: {
            Task {
                isLoading = true
                let transactionHash = await mintNFT()
                isLoading = false
                if let txHash = transactionHash {
                    handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
                }
            }
        }) {
            if isLoading {
                ProgressView()
            } else {
                Text("Mint NFT")
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.bordered)
        .disabled(!stateIsReady || isLoading)
    }

    func mintNFT() async -> String? {
        // TODO: Get access token from Openfort singleton
        let accessToken = await OFSDK.shared.getAccessToken { result in
            switch result {
            case .success(let token):
                print("Access token: \(token)")
            case .failure(let error):
                print("Failed to get access token: \(error)")
            }
        }

        // Prepare your API call (use your endpoint)
        guard let url = URL(string: "https://yourdomain.com/api/protected-collect") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle error
                print("Failed to mint NFT. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            // Parse JSON for transactionIntentId and userOperationHash
            let collectResponse = try JSONDecoder().decode(CollectResponse.self, from: data)

            // TODO: Send signature transaction intent request with Openfort
            let transactionHash = try await OFSDK.shared.sendSignatureTransactionIntentRequest(params: OFSendSignatureTransactionIntentRequestParams(transactionIntentId: collectResponse.transactionIntentId, signableHash: collectResponse.userOperationHash))?.transactionHash
            

            return transactionHash
        } catch {
            print("Mint NFT error: \(error)")
            return nil
        }
    }

    struct CollectResponse: Decodable {
        let transactionIntentId: String
        let userOperationHash: String
    }
}

// --- Usage ---
// BackendMintButton(handleSetMessage: { url in print(url) })

// NOTE:
// - You need to replace `OFSDK.shared.getAccessToken()` and `sendSignatureTransactionIntentRequest`
//   with your actual Openfort Swift SDK implementation.
// - The `stateIsReady` flag should be set using your app's embedded state.
