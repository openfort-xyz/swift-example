//
//  SharedComponents.swift
//  OpenfortAuthorization
//

import SwiftUI

// MARK: - Social Button

struct SocialButton: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(text)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .foregroundColor(.blue)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
    }
}

// MARK: - Password Field

struct PasswordField: View {
    let label: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                if showPassword {
                    TextField("Password", text: $text)
                        .autocapitalization(.none)
                } else {
                    SecureField("Password", text: $text)
                        .autocapitalization(.none)
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Password Validation

enum PasswordValidation {
    static func validate(_ pw: String) -> Bool {
        let lower = pw.range(of: "[a-z]", options: .regularExpression) != nil
        let upper = pw.range(of: "[A-Z]", options: .regularExpression) != nil
        let special = pw.range(of: "[!@#%&*]", options: .regularExpression) != nil
        let digit = pw.range(of: "\\d", options: .regularExpression) != nil
        return pw.count >= 8 && lower && upper && special && digit
    }
}

// MARK: - Or Divider

struct OrDivider: View {
    var label: String = "Or continue with"

    var body: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray.opacity(0.3))
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 16)
    }
}
