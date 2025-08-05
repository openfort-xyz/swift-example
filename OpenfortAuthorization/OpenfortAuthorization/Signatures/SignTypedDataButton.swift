//
//  SignTypedDataButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct SignTypedDataButton: View {
    let handleSetMessage: (String) -> Void
    @State var embeddedState: OFEmbeddedState

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                Task {
                    await handleSignTypedData()
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign Typed Message")
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(embeddedState != .ready || isLoading)

            // Link to show the typed message definition
            Link("View typed message",
                 destination: URL(string: "https://github.com/openfort-xyz/sample-browser-nextjs-embedded-signer/blob/main/src/components/Signatures/SignTypedDataButton.tsx#L25")!)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }

    private func handleSignTypedData() async {
        guard embeddedState == .ready else { return }
        isLoading = true
        defer { isLoading = false }

        // Set up the domain, types, and message, similar to your React code
        let domain: [String: Any] = [
            "name": "Openfort",
            "version": "0.5",
            "chainId": 80002,
            "verifyingContract": "0x9b5AB198e042fCF795E4a0Fa4269764A4E8037D2"
        ]
        let types: [String: [[String: String]]] = [
            "Mail": [
                ["name": "from", "type": "Person"],
                ["name": "to", "type": "Person"],
                ["name": "content", "type": "string"]
            ],
            "Person": [
                ["name": "name", "type": "string"],
                ["name": "wallet", "type": "address"]
            ]
        ]
        let data: [String: Any] = [
            "from": [
                "name": "Alice",
                "wallet": "0x2111111111111111111111111111111111111111"
            ],
            "to": [
                "name": "Bob",
                "wallet": "0x3111111111111111111111111111111111111111"
            ],
            "content": "Hello!"
        ]
        
        do {
            let params = OFSignTypedDataParams(
                domain: domain,
                types: types,
                value: data
            )
            let result = try await OFSDK.shared.signTypedData(params: params)
            handleSetMessage(result.signature ?? "Signed!")
        } catch {
            print("Failed to sign typed message:", error)
            // You could display an error toast here if you wish
        }
    }
}
