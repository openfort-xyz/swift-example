//
//  RegisterView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailConfirmation: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String? = nil
    @State private var toast: ToastState?
    private var openfort = OFSDK.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    Spacer(minLength: 40)
                    VStack(alignment: .leading, spacing: 0) {
                        if emailConfirmation {
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.seal.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Check your email to confirm")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("You've successfully signed up. Please check your email to confirm your account before signing in to the Openfort dashboard.")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding(.leading, 2)
                            }
                            .padding()
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                        } else {
                            Text("Sign up for account")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 24)

                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading) {
                                        Text("First name")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("First name", text: $firstName)
                                            .textInputAutocapitalization(.words)
                                            .styledTextField()
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Last name")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Last name", text: $lastName)
                                            .textInputAutocapitalization(.words)
                                            .styledTextField()
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Text("Email address")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .styledTextField()
                                }
                                VStack(alignment: .leading) {
                                    PasswordField(label: "Password", text: $password)
                                    Text("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
                                        .font(.caption2)
                                        .foregroundColor(error == "invalidPassword" ? .red : .gray)
                                        .fontWeight(error == "invalidPassword" ? .medium : .regular)
                                        .padding(.top, 3)
                                }
                            }
                            .padding(.bottom, 12)

                            Button(action: {
                                Task {
                                    await signUp()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Get started today")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(isLoading)
                            .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }

                        OrDivider()

                        VStack(spacing: 8) {
                            SocialButton(text: "Continue with Google", icon: "globe") {
                                handleSocialAuth(provider: .google)
                            }
                            SocialButton(text: "Continue with Twitter", icon: "bird") {
                                handleSocialAuth(provider: .twitter)
                            }
                            SocialButton(text: "Continue with Facebook", icon: "f.square") {
                                handleSocialAuth(provider: .facebook)
                            }
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            Text("By signing up, you accept ")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            HStack(spacing: 0) {
                                Button(action: { openURL(URL(string: "https://www.openfort.io/terms")!) }) {
                                    Text("user terms")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(", ")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Button(action: { openURL(URL(string: "https://www.openfort.io/privacy")!) }) {
                                    Text("privacy policy")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(" and ")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Button(action: { openURL(URL(string: "https://www.openfort.io/developer-terms")!) }) {
                                    Text("developer terms of use")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(".")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            Text("Have an account?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Button("Sign in") {
                                dismiss()
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        }
                        .padding(.top, 18)
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
        }.onOpenURL { url in
            if url.host == "login",
               let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                            .queryItems?
                            .first(where: { $0.name == "state" })?.value {
                UserDefaults.standard.set(state, forKey: "openfort:email_verification_state")
                isLoading = false
                emailConfirmation = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
        }
    }

    private func handleSocialAuth(provider: OFOAuthProvider) {
        Task {
            do {
                if let result = try await openfort.initOAuth(
                    params: OFInitOAuthParams(
                        provider: provider.rawValue,
                        options: ["redirectTo": AnyCodable(RedirectManager.makeLink(path: "login")?.absoluteString ?? "")]
                    )
                ), let urlString = result.url, let url = URL(string: urlString) {
                    openURL(url)
                }
                isLoading = false
                emailConfirmation = true
                toast = .success("Successfully signed up with " + provider.rawValue.capitalized)
            } catch {
                toast = .error("Failed to sign in with \(provider.rawValue.capitalized): \(error)")
            }
        }
    }

    func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }

    func signUp() async {
        guard PasswordValidation.validate(password) else {
            error = "invalidPassword"
            toast = .error("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
            return
        }
        error = nil
        isLoading = true
        do {
            let result = try await openfort.signUpWithEmailPassword(params: OFSignUpWithEmailPasswordParams(email: email, password: password, options: OFSignUpWithEmailPasswordOptionsParams(data: ["name": "\(firstName) \(lastName)"])))

            if let action = result?.action, action == "verify_email" {
                try await verifyEmail()
                UserDefaults.standard.set(email, forKey: "openfort:email")
                isLoading = false
                toast = .info("Email verification sent! Check your email.")
                return
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isLoading = false
            emailConfirmation = true
            toast = .success("Successfully signed up!")
        } catch {
            isLoading = false
            toast = .error("Failed to sign up: \(error)")
            return
        }
    }

    private func verifyEmail() async throws {
        try await openfort.requestEmailVerification(params: OFRequestEmailVerificationParams(email: email, redirectUrl: RedirectManager.makeLink(path: "login")?.absoluteString ?? ""))
    }
}

#Preview {
    RegisterView()
}
