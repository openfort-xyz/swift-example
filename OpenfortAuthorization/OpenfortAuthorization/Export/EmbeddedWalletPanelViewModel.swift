//
//  EmbeddedWalletPanelViewModel.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import Foundation
import OpenfortSwift

class EmbeddedWalletPanelViewModel: ObservableObject {
    @Published var embeddedState: OFEmbeddedState = .none
    @Published var embeddedAccount: OFEmbeddedAccount?

    init(embeddedState: OFEmbeddedState, embeddedAccount: OFEmbeddedAccount?) {
        self.embeddedState = embeddedState
        self.embeddedAccount = embeddedAccount
    }

    func exportPrivateKey() async throws -> String {
         try await OFSDK.shared.exportPrivateKey() ?? ""
    }

    @MainActor
    func setWalletRecovery(method: String, password: String?) async throws {
        let session = try await getEncryptionSession()
        if embeddedAccount?.recoveryMethod == .password {
            try await OFSDK.shared.setRecoveryMethod(params: OFSetRecoveryMethodParams(previousRecovery: OFRecoveryParamsDTO(recoveryMethod: .password, password: password),  newRecovery: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session)))
        } else {
            try await OFSDK.shared.setRecoveryMethod(params: OFSetRecoveryMethodParams(previousRecovery: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session), newRecovery: OFRecoveryParamsDTO(recoveryMethod: .password, password: password)))
        }
    }
}
