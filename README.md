# Openfort Swift SDK Example

A SwiftUI example application demonstrating how to integrate the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) for embedded wallet functionality, authentication, message signing, and account recovery.

## Features

- **Authentication** - Email/password, email OTP, OAuth (Google, Twitter, Facebook), Apple Sign-In with optional biometrics, and guest sign-up
- **Registration** - Email/password sign-up with email verification
- **Password Reset** - Forgot password and reset via deep link
- **Embedded Wallet** - Automatic wallet creation with configurable recovery (password or automatic)
- **Message Signing** - Sign plain text messages and EIP-712 typed data
- **Private Key Export** - Export the embedded wallet's private key
- **OAuth Linking** - Link additional social accounts to an existing user
- **Wallet Recovery** - Switch between password and automatic recovery methods

## Requirements

- iOS 16.6+
- Xcode 16.4+
- Swift 5.0

## Getting Started

### 1. Create an Openfort Application

1. Sign up at [openfort.xyz](https://www.openfort.xyz)
2. Create a new project in your Openfort Dashboard
3. Copy your **Publishable Key** and **Shield Publishable Key** from the Developers section

### 2. Configure the Example

Open `OpenfortAuthorization/OpenfortAuthorization/OFConfig.plist` and set the following keys:

| Key | Required | Description |
|-----|----------|-------------|
| `openfortPublishableKey` | Yes | Your Openfort publishable key |
| `shieldPublishableKey` | Yes | Your Shield publishable key |
| `backendUrl` | No | Backend API URL |
| `iframeUrl` | No | Iframe environment URL |
| `shieldUrl` | No | Shield service URL |
| `debug` | No | Enable debug logging (boolean) |

### 3. Open and Run

1. Open `OpenfortSwift.xcworkspace` in Xcode
2. Select the `OpenfortAuthorization` scheme
3. Choose your target device or simulator
4. Build and run (Cmd+R)

### Build from Command Line

```bash
xcodebuild -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -configuration Debug build
```

## Project Structure

```
OpenfortAuthorization/OpenfortAuthorization/
├── OpenfortAuthorizationApp.swift    # @main entry point
├── AppDelegate.swift                 # SDK initialization (OFSDK.setupSDK())
├── LoginView.swift                   # Multi-method authentication
├── RegisterView.swift                # Email/password registration
├── HomeView.swift                    # Main authenticated interface
├── HomeViewModel.swift               # Home state management (ObservableObject)
├── AccountRecoveryView.swift         # Wallet recovery setup
├── ForgotPasswordView.swift          # Request password reset
├── ResetPasswordView.swift           # Reset password with token
├── EmailOTPSheet.swift               # Email OTP verification
├── Signatures/                       # Message & typed data signing
├── OAuth/                            # Social login linking
├── Export/                           # Private key export & wallet management
├── User/                             # User info display
├── WalletRecovery/                   # Recovery method switching
└── Utils/                            # Shared components & helpers
```

## Architecture

The app follows a **SwiftUI + MVVM** pattern:

- **LoginView** is the root view, managing authentication state
- **HomeView** renders different UI based on embedded wallet state (`.embeddedSignerNotConfigured` -> `.creatingAccount` -> `.ready`)
- **HomeViewModel** subscribes to `OFSDK.shared.embeddedStatePublisher` via Combine
- Deep links use a custom URL scheme derived from the bundle ID (`openfortsample://`)

## Dependencies

Managed via Swift Package Manager:

- [OpenfortSwift](https://github.com/openfort-xyz/swift-sdk) (>= 1.0.0) - Openfort SDK for authentication, wallet management, and signing

## License

See the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) repository for license information.
