//
//  OpenfortAuthorizationTests.swift
//  OpenfortAuthorizationTests
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import XCTest
import OpenfortSwift
@testable import OpenfortAuthorization

/// Runs inside the sample app against the live Openfort test project in `OFConfig.plist`.
@MainActor
final class OpenfortAuthorizationTests: XCTestCase {

    func testGuestWalletLifecycle() async throws {
        let sdk = OFSDK.shared
        try await sdk.waitUntilReady(timeout: 60)

        if (try? await sdk.getUser()) != nil {
            try await sdk.logOut()
        }

        let auth = try await sdk.signUpGuest()
        XCTAssertNotNil(auth?.user?.id, "Guest sign-up returned no user")
        try await waitForEmbeddedState(.embeddedSignerNotConfigured)

        let session = try await getEncryptionSession()
        let account = try await sdk.configure(params: OFEmbeddedAccountConfigureParams(
            chainId: 80002,
            recoveryParams: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session)
        ))
        XCTAssertTrue(account?.address.hasPrefix("0x") ?? false, "configure returned no wallet address")

        let signature = try await sdk.signMessage(params: OFSignMessageParams(message: "Hello!"))
        XCTAssertTrue(signature?.hasPrefix("0x") ?? false, "signMessage returned no signature")

        try await sdk.logOut()
    }

    /// The app only offers wallet setup once the SDK reports this state; calling `configure`
    /// before openfort-js has finished reacting to the login races its signer re-initialisation.
    private func waitForEmbeddedState(_ expected: OFEmbeddedState, timeout: TimeInterval = 30) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while OFSDK.shared.embeddedState != expected {
            XCTAssertLessThan(Date(), deadline, "Embedded state never became \(expected)")
            if Date() >= deadline { return }
            try await Task.sleep(for: .milliseconds(100))
        }
    }
}
