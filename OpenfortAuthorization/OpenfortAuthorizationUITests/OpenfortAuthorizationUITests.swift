//
//  OpenfortAuthorizationUITests.swift
//  OpenfortAuthorizationUITests
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import XCTest

/// End-to-end smoke test against the live Openfort test project configured in `OFConfig.plist`.
/// Requires network access and the app's bundle identifier to be allowlisted in the dashboard.
final class OpenfortAuthorizationUITests: XCTestCase {

    private let network: TimeInterval = 60
    private let walletSetup: TimeInterval = 120

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGuestSignInConfigureWalletAndSign() throws {
        let app = XCUIApplication()
        app.launch()

        logOutIfSessionRestored(app)

        let guestButton = app.buttons["Continue as Guest"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: network), "Login screen did not appear")
        guestButton.tap()

        let automaticRecovery = app.buttons["Continue with Automatic Recovery"]
        XCTAssertTrue(automaticRecovery.waitForExistence(timeout: network), "Guest sign-up did not reach the recovery screen")
        automaticRecovery.tap()

        let signMessage = app.buttons["Sign Message"]
        XCTAssertTrue(signMessage.waitForExistence(timeout: walletSetup), "Embedded wallet never became ready")
        XCTAssertTrue(signMessage.waitUntilEnabled(timeout: walletSetup), "Sign Message stayed disabled")
        signMessage.tap()
        expectResult(app, prefix: "Signed message: 0x")

        let signTypedData = app.buttons["Sign Typed Message"]
        XCTAssertTrue(signTypedData.waitForExistence(timeout: network))
        signTypedData.tap()
        expectResult(app, prefix: "Signed typed data: 0x")

        app.buttons["Logout"].tap()
        XCTAssertTrue(guestButton.waitForExistence(timeout: network), "Logout did not return to the login screen")
    }

    /// A previous run leaves its session in the simulator keychain, so the app may restore it on launch.
    private func logOutIfSessionRestored(_ app: XCUIApplication) {
        let logout = app.buttons["Logout"]
        if logout.waitForExistence(timeout: 10) {
            logout.tap()
        }
    }

    private func expectResult(_ app: XCUIApplication, prefix: String) {
        let result = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: network), "No result starting with '\(prefix)'")
        app.buttons["Dismiss"].tap()
        XCTAssertTrue(result.waitForNonExistence(timeout: 5), "Result overlay did not dismiss")
    }
}

private extension XCUIElement {
    func waitUntilEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
