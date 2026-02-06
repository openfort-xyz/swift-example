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
    let viewModel: EmbeddedWalletPanelViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Embedded wallet").font(.headline)
            HStack {
                Text("Export wallet private key: ").fontWeight(.medium)
                Button("Export") {
                    Task {
                        do {
                            let response = try await viewModel.exportPrivateKey()
                            if !response.isEmpty {
                                handleSetMessage("Exported private key: \(response)")
                            }
                        } catch {
                            handleSetMessage("Failed to export private key")
                        }
                    }
                }
            }
            Text("Change wallet recovery:")
            SetWalletRecoveryButton(handleSetMessage: handleSetMessage, viewModel: viewModel)
        }
        .cardStyle()
    }
}
