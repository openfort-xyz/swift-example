//
//  HomeViewModel.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import Foundation
import OpenfortSwift
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: OFEmbeddedState = .none
    @Published var user: OFUser?
    @Published var embeddedAccount: OFEmbeddedAccount?
    @Published var message: String = ""
    @Published var lastMessage: String?
    var onLogout: (() -> Void)?

    private var cancellable: AnyCancellable?

    lazy var handleRecovery: (_ method: RecoveryMethod, _ password: String?) async throws -> Void = { method, password in
        let chainId = 80002

        do {
            if method == .password {
                let recoveryParams = OFRecoveryParamsDTO(recoveryMethod: .password, password: password)
                let result = try await OFSDK.shared.configure(params: OFEmbeddedAccountConfigureParams(chainId: chainId, recoveryParams: recoveryParams))
                self.embeddedAccount = result
                self.message = "Embedded wallet configured successfully with password recovery.\n\n" + self.message
            } else {
                let session = try await getEncryptionSession()

                let recoveryParams = OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session)
                let result = try await OFSDK.shared.configure(params: OFEmbeddedAccountConfigureParams(chainId: chainId, recoveryParams: recoveryParams))
                self.embeddedAccount = result
                self.message = "Embedded wallet configured successfully with automatic recovery.\n\n" + self.message
            }
        } catch {
            self.message = "Error configuring embedded wallet: \(error.localizedDescription)\n\n" + self.message
            throw error
        }
    }

    init() {
        self.cancellable = OFSDK.shared.embeddedStatePublisher
            .replaceNil(with: .none)
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)

        Task {
            await loadUser()
        }
    }

    func loadUser() async {
        do {
            user = try await OFSDK.shared.getUser()
        } catch {
            message = "Error loading user: \(error)\n\n" + message
        }
    }

    func logout() async {
        do {
            try await OFSDK.shared.logOut()
        } catch let error {
            message = "Error logging out: \(error)\n\n" + message
            return
        }
        onLogout?()
    }

    func handleSetMessage(_ msg: String) {
        message = "> \(msg)\n\n" + message
        lastMessage = msg
    }
}
