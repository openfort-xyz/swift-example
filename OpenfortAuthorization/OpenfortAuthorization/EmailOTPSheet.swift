//
//  EmailOTPSheet.swift
//  OpenfortAuthorization
//

import SwiftUI
import OpenfortSwift

struct EmailOTPSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onSuccess: () -> Void

    @State private var email: String = ""
    @State private var otp: String = ""
    @State private var step: Step = .enterEmail
    @State private var isLoading: Bool = false
    @State private var toast: ToastState?

    private let openfort = OFSDK.shared

    enum Step {
        case enterEmail
        case enterOTP
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if step == .enterEmail {
                    enterEmailView
                } else {
                    enterOTPView
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("Sign in with Email Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toast($toast)
        }
    }

    @ViewBuilder
    private var enterEmailView: some View {
        Text("Enter your email address and we'll send you a one-time code.")
            .font(.subheadline)
            .foregroundColor(.secondary)

        VStack(alignment: .leading) {
            Text("Email address")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .styledTextField()
        }

        Button(action: { Task { await sendCode() } }) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                Text("Send Code")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .disabled(isLoading || email.isEmpty)
        .background(isLoading || email.isEmpty ? Color.gray.opacity(0.2) : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }

    @ViewBuilder
    private var enterOTPView: some View {
        Text("Enter the 6-digit code sent to **\(email)**")
            .font(.subheadline)
            .foregroundColor(.secondary)

        VStack(alignment: .leading) {
            Text("Verification code")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("000000", text: $otp)
                .keyboardType(.numberPad)
                .styledTextField()
        }

        Button(action: { Task { await verifyCode() } }) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                Text("Verify")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .disabled(isLoading || otp.isEmpty)
        .background(isLoading || otp.isEmpty ? Color.gray.opacity(0.2) : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)

        Button("Resend code") {
            Task { await sendCode() }
        }
        .font(.footnote)
        .foregroundColor(.blue)

        Button("Use a different email") {
            otp = ""
            step = .enterEmail
        }
        .font(.footnote)
        .foregroundColor(.gray)
    }

    private func sendCode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await openfort.requestEmailOtp(params: OFRequestEmailOtpParams(email: email))
            step = .enterOTP
            toast = .success("Code sent to \(email)")
        } catch {
            toast = .error("Failed to send code: \(error.localizedDescription)")
        }
    }

    private func verifyCode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await openfort.logInWithEmailOtp(params: OFLogInWithEmailOtpParams(email: email, otp: otp))
            toast = .success("Signed in!")
            onSuccess()
            dismiss()
        } catch {
            toast = .error("Verification failed: \(error.localizedDescription)")
        }
    }
}
