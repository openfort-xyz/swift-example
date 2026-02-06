//
//  ContentView.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import SwiftUI
import OpenfortSwift
import AuthenticationServices
import CryptoKit
import UIKit

struct LoginView: View {

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    @State private var showEmailOTP = false
    @State private var toast: ToastState?
    @State private var isSignedIn = false
    @StateObject private var homeViewModel = HomeViewModel()

    @State private var useBiometrics: Bool = false
    @State private var currentNonce: String?

    private let openfort = OFSDK.shared

    var body: some View {
        NavigationStack {
            if !isSignedIn {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    VStack {
                        Spacer(minLength: 40)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sign in to account")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 24)

                            VStack(spacing: 18) {
                                VStack(alignment: .leading) {
                                    Text("Email address")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .styledTextField()
                                }

                                PasswordField(label: "Password", text: $password)

                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {
                                        showForgotPassword = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.bottom, 8)

                            Button(action: {
                                Task {
                                    await signIn()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Sign in to account")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(isLoading)
                            .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 12)

                            // Login options
                            socialButtonsView

                            HStack {
                                Text("Don't have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button("Sign up") {
                                    showSignUp = true
                                }
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            }
                            .padding(.top, 24)
                        }
                        .padding(28)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 8)

                        Spacer()
                    }
                }
                .toast($toast)
                // Modals
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
                .sheet(isPresented: $showSignUp) {
                    RegisterView()
                }
                .sheet(isPresented: $showEmailOTP) {
                    EmailOTPSheet {
                        isSignedIn = true
                        toast = .success("Signed in with Email Code!")
                    }
                }
            } else {
                HomeView(viewModel: homeViewModel).onAppear {
                    homeViewModel.onLogout = {
                        isSignedIn = false
                        toast = .info("Signed Out!")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await checkExistingSession()
                await verifyEmail()
            }
        }
    }

    @ViewBuilder
    private var socialButtonsView: some View {
        VStack(spacing: 8) {
            OrDivider()

            VStack(spacing: 8) {
                LoginOptionButton(text: "Continue with Email Code", icon: "envelope") {
                    showEmailOTP = true
                }

                LoginOptionButton(text: "Continue as Guest", icon: "person") {
                    Task { await continueAsGuest() }
                }

                LoginOptionButton(text: "Continue with Google", icon: "globe") {
                    continueWithGoogle()
                }

                // Sign in with Apple
                SignInWithAppleButton(.signIn, onRequest: { request in
                    let nonce = AppleAuthManager.randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleAuthManager.sha256(nonce)
                }, onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        guard
                            let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                            let tokenData = credential.identityToken,
                            let idToken = String(data: tokenData, encoding: .utf8),
                            !idToken.isEmpty
                        else {
                            toast = .error("Apple Sign-In: missing ID token")
                            return
                        }
                        Task {
                            do {
                                if useBiometrics {
                                    let anchor = await AppleAuthManager.currentPresentationAnchor()
                                    let manager = AppleAuthManager(presentationAnchor: anchor)
                                    _ = try await manager.authenticateWithBiometrics(reason: "Authenticate to continue")
                                }
                                _ = try await OFSDK.shared.loginWithIdToken(
                                    params: OFLoginWithIdTokenParams(provider: OFAuthProvider.apple.rawValue, token: idToken)
                                )
                                isSignedIn = true
                                toast = .success("Signed in with Apple!")
                            } catch {
                                toast = .error("Apple Sign-In failed: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        toast = .error("Apple Sign-In failed: \(error.localizedDescription)")
                    }
                })
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Toggle("Require Face ID / Touch ID before signing in", isOn: $useBiometrics)
                    .font(.footnote)
                    .tint(.blue)
                    .accessibilityHint("When enabled, biometric authentication is required before signing in")
            }
        }.onOpenURL { url in
            // Handle OAuth redirect carrying access/refresh tokens and player id
            if url.host == "login", let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                let qp: [String: String] = comps.queryItems?.reduce(into: [:]) { dict, item in
                    if let v = item.value { dict[item.name] = v }
                } ?? [:]

                if let accessToken = qp["access_token"],
                   let refreshToken = qp["refresh_token"],
                   let playerId = qp["player_id"],
                   !accessToken.isEmpty, !refreshToken.isEmpty, !playerId.isEmpty {

                    isLoading = true
                    toast = .info("Signing in...")

                    Task {
                        do {
                            try await openfort.storeCredentials(params: OFStoreCredentialsParams(token: accessToken, userId: playerId))
                            isSignedIn = true
                            isLoading = false
                            toast = .success("Signed in!")
                        } catch {
                            isLoading = false
                            toast = .error("Failed to store credentials: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private func verifyEmail() async {
        if let _ = UserDefaults.standard.string(forKey: "openfort:email"), let state = UserDefaults.standard.string(forKey: "openfort:email_verification_state") {
            do {
                try await OFSDK.shared.verifyEmail(params: OFVerifyEmailParams(token: state))
                isLoading = false
                toast = .success("Email verified successfully!")
            } catch {
                isLoading = false
                toast = .error("Email not verified!")
            }

            UserDefaults.standard.removeObject(forKey: "openfort:email")
            UserDefaults.standard.removeObject(forKey: "openfort:email_verification_state")
        }
    }

    private func checkExistingSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let _ = try await openfort.getUser() {
                isSignedIn = true
                toast = .info("Welcome back!")
            }
        } catch {
            // Stay on login screen silently
        }
    }

    private func signIn() async {
        isLoading = true
        let username = self.email
        let password = self.password

        do {
            let result = try await OFSDK.shared.logInWithEmailPassword(params: OFLogInWithEmailPasswordParams(email: username, password: password))
            print(result ?? "Empty response!")
            isLoading = false
            toast = .success("Signed in!")
            isSignedIn = true
        } catch {
            toast = .error("Failed to sign in: \(error.localizedDescription)")
            isLoading = false
            return
        }
    }

    private func continueAsGuest() async {
        isLoading = true
        do {
            _ = try await openfort.signUpGuest()
            isSignedIn = true
            toast = .success("Signed in as Guest!")
        } catch {
            toast = .error("Failed to sign in as Guest: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func startOAuth(provider: OFAuthProvider, successMessage: String) {
        isLoading = true
        Task { [providerName = successMessage] in
            defer { isLoading = false }
            do {
                if let result = try await openfort.initOAuth(
                    params: OFInitOAuthParams(
                        provider: provider.rawValue,
                        options: ["redirectTo": AnyCodable(RedirectManager.makeLink(path: "login")?.absoluteString ?? "")]
                    )
                ), let urlString = result.url, let url = URL(string: urlString) {
                    await UIApplication.shared.open(url)
                }
                isSignedIn = true
                toast = .success(providerName)
            } catch {
                toast = .error("\(successMessage.replacingOccurrences(of: "Signed in with ", with: "")) sign-in failed: \(error.localizedDescription)")
            }
        }
    }

    private func continueWithGoogle() {
        startOAuth(provider: .google, successMessage: "Signed in with Google!")
    }

}

#Preview {
    LoginView()
}

