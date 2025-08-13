//
//  EmbeddedWalletPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct EmbeddedWalletPanelView: View {
    let handleSetMessage: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Embedded wallet").font(.headline)
            HStack {
                Text("Export wallet private key: ").fontWeight(.medium)
                Button("Export") {
                    Task {
                        do {
                            _ = try await OFSDK.shared.exportPrivateKey()
                            handleSetMessage("Exported private key")
                        } catch {
                            handleSetMessage("Failed to export private key")
                        }
                    }
                }
            }
            Text("Change wallet recovery:")
            SetWalletRecoveryButton(viewModel: EmbeddedWalletPanelViewModel(), handleSetMessage: handleSetMessage)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

class EmbeddedWalletPanelViewModel: ObservableObject {
    @Published var embeddedState: OFEmbeddedState = .none

    func exportPrivateKey() async throws -> String {
        // Your Openfort SDK export logic here
        // If SDK throws or returns an error, rethrow it or handle accordingly
        // Return the exported key as a String
        return ""
    }

    @MainActor
    func setWalletRecovery(method: String, password: String?) async throws {
        do {
            try await OFSDK.shared.setEmbeddedRecovery(params: OFSetEmbeddedRecoveryParams(recoveryMethod: method, recoveryPassword: password ?? "", encryptionSession: ""))
        } catch {
            throw error
        }
    }
}
