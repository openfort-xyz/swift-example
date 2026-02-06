//
//  ResetPasswordView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct ResetPasswordView: View {
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var toast: ToastState?

    @Environment(\.dismiss) private var dismiss

    let state: String
    let email: String

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack {
                Spacer(minLength: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Reset Your Password")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 24)

                    VStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            PasswordField(label: "", text: $password)
                                .background(Color.white)

                            Text("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
                                .font(.caption)
                                .foregroundColor(error == "invalidPassword" ? .red : .gray)
                                .fontWeight(error == "invalidPassword" ? .medium : .regular)
                                .padding(.top, 4)
                        }
                    }

                    Button(action: {
                        submit()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text("Save New Password")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .disabled(isLoading)
                    .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 24)

                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        NavigationLink(destination: LoginView()) {
                            Text("Sign in")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(28)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 8)

                Spacer()
            }
            .padding(.top, 20)
        }
        .toast($toast)
    }

    func submit() {
        isLoading = true
        error = nil
        if !PasswordValidation.validate(password) {
            error = "invalidPassword"
            isLoading = false
            return
        }

        Task {
            defer { isLoading = false }
            do {
                let params = OFResetPasswordParams(password: password, token: state)
                try await OFSDK.shared.resetPassword(params: params)
                toast = .success("Password reset successful!")
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                dismiss()
            } catch {
                toast = .error("Failed to reset password. Please try again.")
            }
        }
    }
}

#Preview {
    ResetPasswordView(state: "", email: "")
}
