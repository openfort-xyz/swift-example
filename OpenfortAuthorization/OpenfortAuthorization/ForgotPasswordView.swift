//
//  ForgotPasswordView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-12.
//

import SwiftUI
import OpenfortSwift

struct ForgotPasswordView: View {
    // MARK: - State
    @State private var email: String = UserDefaults.standard.string(forKey: "openfort:email") ?? ""
    @State private var isLoading: Bool = false
    @State private var toast: ToastState?
    @State private var showResetPassword = false
    @State private var resetState: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 16) {
                            resetPasswordHeader
                            sendResetEmailButton
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Button("login") {
                                    dismiss()
                                }
                                .font(.footnote)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                        .padding(.horizontal)
                        .padding(.top, 24)
                    }
                }
            }
            .toast($toast)
            .onAppear { Task { await checkExistingSession() } }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onOpenURL { url in
                if url.host == "reset-password",
                   let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                                .queryItems?
                                .first(where: { $0.name == "state" })?.value {
                    resetState = state
                    showResetPassword = true
                }
            }.navigationDestination(isPresented: $showResetPassword) {
                ResetPasswordView(state: resetState, email: email)
            }
        }
    }

    // MARK: - Actions
    private func handleSubmit() async {
        guard !email.isEmpty else { return }
        isLoading = true

        do {
            let redirect = redirectURLString()
            let params = OFRequestResetPasswordParams(email: email, redirectUrl: redirect)
            try await OFSDK.shared.requestResetPassword(params: params)
            toast = .success("Successfully sent email")
        } catch {
            toast = .error("Error sending email")
        }
        isLoading = false
    }

    private func checkExistingSession() async {
        do {
            if let _ = try await OFSDK.shared.getUser() {
                dismiss()
            }
        } catch {
            // Ignore errors; stay on this screen
        }
    }

    // MARK: - Helpers
    private func redirectURLString() -> String {
        return RedirectManager.makeLink(path: "reset-password")?.absoluteString ?? ""
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var resetPasswordHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Reset Your Password")
                .font(.title2).bold()
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Email address")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                TextField("name@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var sendResetEmailButton: some View {
        Button(action: { Task { await handleSubmit() } }) {
            HStack {
                if isLoading { ProgressView() }
                Text(isLoading ? "Sending..." : "Send Reset Email")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || !isValidEmail(email))
        .padding(.top, 8)
    }
}
