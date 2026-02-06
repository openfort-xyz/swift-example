# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI example application demonstrating the Openfort Swift SDK integration. It showcases embedded wallet functionality, authentication flows (email/password, email OTP, OAuth, guest, Apple Sign-In), wallet management, message and typed data signing, private key export, and account recovery mechanisms.

## Build & Run Commands

### Build the Project
```bash
xcodebuild -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -configuration Debug build
```

### Run Tests
```bash
# Run all tests
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationTests

# Run UI tests
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationUITests
```

### Clean Build
```bash
xcodebuild clean -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization
```

## Configuration

### OFConfig.plist
The app requires configuration via `OpenfortAuthorization/OpenfortAuthorization/OFConfig.plist`:
- `backendUrl` - Backend API URL (optional)
- `iframeUrl` - Iframe environment URL (optional)
- `openfortPublishableKey` - Openfort publishable key (required)
- `shieldPublishableKey` - Shield publishable key (required)
- `shieldUrl` - Shield service URL (optional)
- `debug` - Enable debug logging (boolean)

### GoogleService-Info.plist
Firebase/Google configuration for OAuth support. Contains `CLIENT_ID`, `REVERSED_CLIENT_ID`, `API_KEY`, `GCM_SENDER_ID`, `BUNDLE_ID`, `PROJECT_ID`, `GOOGLE_APP_ID`.

## Architecture

### SDK Initialization Flow
1. **AppDelegate.swift** - Openfort SDK initialization happens in `application(_:didFinishLaunchingWithOptions:)`
   - Openfort SDK is set up with `OFSDK.setupSDK()`
2. **OpenfortAuthorizationApp.swift** - Entry point using `@main`, uses `@UIApplicationDelegateAdaptor(AppDelegate.self)`, shows `LoginView()` as root

### Authentication Flow
1. **LoginView** - Entry point, handles multiple auth methods:
   - Email/password authentication via `OFSDK.shared.logInWithEmailPassword()`
   - Email OTP (one-time password) via `OFSDK.shared.requestEmailOtp()` and `OFSDK.shared.logInWithEmailOtp()`
   - OAuth (Google, Twitter, Facebook) via `OFSDK.shared.initOAuth()`
   - Apple Sign-In using `SignInWithAppleButton` with optional biometric (Face ID/Touch ID) gate
   - Guest sign-up via `OFSDK.shared.signUpGuest()`
   - Session restoration via `OFSDK.shared.getUser()` on app launch
   - Email verification check on launch via UserDefaults keys

2. **RegisterView** - User registration flow:
   - Email/password sign-up via `OFSDK.shared.signUpWithEmailPassword()`
   - Supports first name/last name metadata
   - Email verification with `OFSDK.shared.requestEmailVerification()`
   - Social sign-up via OAuth (Google, Twitter, Facebook)
   - Password validation: 8+ chars, lowercase, uppercase, special char (`!@#%&*`), digit

3. **EmailOTPSheet** - Two-step email OTP login:
   - Step 1: Enter email, calls `requestEmailOtp()`
   - Step 2: Enter 6-digit code, calls `logInWithEmailOtp()`

4. **ForgotPasswordView** / **ResetPasswordView** - Password reset flow:
   - Requests reset via `OFSDK.shared.requestResetPassword()` with redirect URL
   - Deep link (`openfortsample://reset-password`) carries state token
   - Resets password via `OFSDK.shared.resetPassword()` with token

5. **OAuth Flow** - OAuth providers use deep linking:
   - `initOAuth()` generates authorization URL with redirect URI
   - App opens URL in external browser
   - User completes OAuth flow
   - Redirect URL (scheme: `openfortsample://login`) brings user back to app
   - URL contains `access_token`, `refresh_token`, and `player_id` query parameters
   - Credentials are stored via `OFSDK.shared.storeCredentials()`

6. **Apple Sign-In Flow**:
   - Uses `AppleAuthManager` with cryptographic nonce (SHA256 hashed)
   - Optional biometric gate via `LAContext` (`deviceOwnerAuthentication` policy)
   - Calls `OFSDK.shared.loginWithIdToken()` with Apple JWT

### Embedded Wallet States
The app tracks embedded wallet state via `OFSDK.shared.embeddedStatePublisher`:
- `.none` - No wallet configured
- `.embeddedSignerNotConfigured` - User authenticated but wallet needs recovery setup
- `.creatingAccount` - Account creation in progress
- `.ready` - Wallet fully configured and operational

### Account Recovery System
**AccountRecoveryView** provides two recovery methods:

1. **Password Recovery** - User provides a password to secure wallet recovery:
   - Password is passed to `OFSDK.shared.configure()` with `recoveryMethod: .password`
   - Configuration includes `chainId: 80002` (Polygon Amoy testnet)

2. **Automatic Recovery** - Uses server-side encryption session:
   - Fetches encryption session from backend API (`getEncryptionSession()`)
   - Session string passed to `OFSDK.shared.configure()` with `recoveryMethod: .automatic`
   - Backend endpoint: `https://create-next-app.openfort.io/api/protected-create-encryption-session`

### Wallet Recovery Method Switching
**SetWalletRecoveryButton** (in WalletRecovery/) allows switching recovery methods after initial setup:
- Switch from password to automatic (requires old password + new encryption session)
- Switch from automatic to password (requires new password)
- Uses `OFSDK.shared.setRecoveryMethod()` with previous and new recovery params

### Component Organization
- **Signatures/** - Message and typed data signing components
  - `SignaturesPanelView.swift` - Container panel view
  - `SignMessageButton.swift` - Signs "Hello!" message via `OFSDK.shared.signMessage()`
  - `SignTypedDataButton.swift` - Signs EIP-712 typed data via `OFSDK.shared.signTypedData()`
- **OAuth/** - Social login linking and management
  - `LinkedSocialsPanelView.swift` - Shows linked accounts, get user button, link wallet
  - `LinkOAuthButton.swift` - Links OAuth provider via `OFSDK.shared.initLinkOAuth()`
- **Export/** - Private key export and embedded wallet management
  - `EmbeddedWalletPanelView.swift` - Wallet panel with export and recovery controls
  - `EmbeddedWalletPanelViewModel.swift` - Manages export and recovery switching logic
  - `ExportPrivateKeyButton.swift` - Exports key via `OFSDK.shared.exportPrivateKey()`
- **User/** - User info display
  - `GetUserButton.swift` - Fetches and displays user as pretty-printed JSON
- **WalletRecovery/** - Wallet recovery button
  - `SetWalletRecoveryButton.swift` - UI for switching between recovery methods
- **Utils/** - Shared utilities:
  - `ToastModifier.swift` - Toast notification system (`ToastState`, `.toast()` modifier) with auto-dismiss and persistent result modes
  - `SharedComponents.swift` - Reusable UI components (`SocialButton`, `LoginOptionButton`, `PasswordField`, `PasswordValidation`, `OrDivider`, `CardStyle`, `StyledTextFieldModifier`)
  - `EncryptionSession.swift` - Backend API call for encryption sessions
  - `AppleAuthManager.swift` - Apple authentication, biometric helpers, and crypto utilities (`randomNonceString`, `sha256`, `currentPresentationAnchor`)
  - `RedirectManager.swift` - Deep link URL generation from bundle ID scheme

### HomeView Architecture
**HomeView** serves as the main authenticated interface with different states:
1. Shows `AccountRecoveryView` when `state == .embeddedSignerNotConfigured`
2. Displays loading UI when `state == .creatingAccount`
3. Shows full feature panels when `state == .ready`:
   - Signatures panel (sign message, sign typed data)
   - Linked socials (get user, link OAuth, link wallet)
   - Embedded wallet management (export key, change recovery method)

### ViewModel Pattern
**HomeViewModel** manages home state as an `@ObservableObject`:
- Subscribes to `OFSDK.shared.embeddedStatePublisher` for wallet state changes
- Loads user data with `OFSDK.shared.getUser()`
- Provides `handleRecovery` closure for recovery configuration (chainId: 80002)
- Manages logout flow with `OFSDK.shared.logOut()`
- Tracks message history via `handleSetMessage()` closure

### Deep Link Handling
Deep links are handled via `.onOpenURL` modifier. The URL scheme is derived from the bundle ID's last component, lowercased (e.g., `com.openfort.OpenfortSample` -> `openfortsample`):
- OAuth redirects: `openfortsample://login?access_token=...&refresh_token=...&player_id=...`
- Password reset: `openfortsample://reset-password?state=...`
- Email verification: Stores email and state in UserDefaults, verified on next launch

## Dependencies
The project uses Swift Package Manager for dependencies:
- **OpenfortSwift** (>= 1.0.0) - Main SDK from `https://github.com/openfort-xyz/swift-sdk.git`

Key transitive dependencies include Web3.swift, secp256k1.swift, CryptoSwift, BigInt, PromiseKit, swift-crypto, and swift-nio.

## Common Development Tasks

### Adding a New Authentication Provider
1. Add provider case to `OFAuthProvider` enum (if not already present)
2. Create button in LoginView using `LoginOptionButton` or `SocialButton`
3. Implement handler function following the `startOAuth()` pattern
4. Update deep link handling in `.onOpenURL` if needed

### Adding New Wallet Features
1. Create a new View/Button component in appropriate subdirectory
2. Add to HomeView's feature panels section
3. Pass `handleSetMessage` closure for logging results
4. Use `OFSDK.shared` for SDK interactions
5. Gate features with `embeddedState == .ready` check

### Testing OAuth Flows
OAuth requires deep link redirection. Test using:
1. Run app in simulator
2. Trigger OAuth flow (opens Safari)
3. Complete authentication
4. Safari redirects to `openfortsample://login` scheme
5. Simulator automatically returns to app with credentials

## Project Structure
- Workspace: `OpenfortSwift.xcworkspace`
- Target: `OpenfortAuthorization`
- Bundle ID: `com.openfort.OpenfortSample`
- Minimum iOS: 16.6
- Swift Version: 5.0
- Xcode: 16.4+
- Main App: `OpenfortAuthorizationApp.swift` (entry point using `@main`)
- Entitlements: Sign in with Apple, App Sandbox

## Source File Map

```
OpenfortAuthorization/OpenfortAuthorization/
├── OpenfortAuthorizationApp.swift    # @main entry point
├── AppDelegate.swift                 # SDK initialization
├── LoginView.swift                   # Multi-method auth entry point
├── RegisterView.swift                # Email/password registration
├── HomeView.swift                    # Main authenticated interface
├── HomeViewModel.swift               # Home state management
├── AccountRecoveryView.swift         # Wallet recovery setup
├── ForgotPasswordView.swift          # Password reset request
├── ResetPasswordView.swift           # Password reset with token
├── EmailOTPSheet.swift               # Email OTP verification
├── Signatures/
│   ├── SignaturesPanelView.swift
│   ├── SignMessageButton.swift
│   └── SignTypedDataButton.swift
├── OAuth/
│   ├── LinkedSocialsPanelView.swift
│   └── LinkOAuthButton.swift
├── Export/
│   ├── EmbeddedWalletPanelView.swift
│   ├── EmbeddedWalletPanelViewModel.swift
│   └── ExportPrivateKeyButton.swift
├── User/
│   └── GetUserButton.swift
├── WalletRecovery/
│   └── SetWalletRecoveryButton.swift
└── Utils/
    ├── SharedComponents.swift
    ├── ToastModifier.swift
    ├── EncryptionSession.swift
    ├── AppleAuthManager.swift
    └── RedirectManager.swift
```
