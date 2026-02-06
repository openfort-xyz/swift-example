# OpenfortAuthorization

A companion project to the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) demonstrating embedded wallet integration in a SwiftUI application.

## Overview

This example shows how to:

- Configure the Openfort Swift SDK in a SwiftUI application
- Implement multiple authentication methods (email/password, email OTP, OAuth, Apple Sign-In, guest)
- Handle user registration with email verification
- Manage embedded wallet states and account recovery
- Sign messages and EIP-712 typed data
- Export private keys
- Link additional OAuth providers to an existing account
- Switch between wallet recovery methods (password and automatic)

## Setup

### 1. Create an Openfort Application

1. Sign up at [openfort.xyz](https://www.openfort.xyz)
2. Create a new project in your Openfort Dashboard
3. Copy your **Publishable Key** and **Shield Publishable Key** from the Developers section

### 2. Configure the Example

Open `OpenfortAuthorization/OFConfig.plist` and set the following keys:

| Key | Required | Description |
|-----|----------|-------------|
| `openfortPublishableKey` | Yes | Your Openfort publishable key |
| `shieldPublishableKey` | Yes | Your Shield publishable key |
| `backendUrl` | No | Backend API URL |
| `iframeUrl` | No | Iframe environment URL |
| `shieldUrl` | No | Shield service URL |
| `debug` | No | Enable debug logging (boolean) |

### 3. Run the App

1. Open `OpenfortSwift.xcworkspace` in Xcode (from the repository root)
2. Select the `OpenfortAuthorization` scheme
3. Choose your target device or simulator
4. Build and run the project (Cmd+R)
