//
//  AccountRecoveryView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI

struct AccountRecoveryView: View {
    @State private var password: String = ""
    @State private var loadingPwd: Bool = false
    @State private var loadingAut: Bool = false
    @State private var toast: ToastState?
    @FocusState private var focused: Bool

    var handleRecovery: (_ method: RecoveryMethod, _ password: String?) async throws -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Account recovery")
                .font(.title2)
                .bold()
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                TextField("Password to secure your recovery", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($focused)
                    .padding(.bottom, 12)

                Button {
                    Task {
                        loadingPwd = true
                        do {
                            try await handleRecovery(.password, password)
                            toast = .success("Recovery configured successfully!")
                        } catch _ as MissingRecoveryPasswordError {
                            toast = .error("Missing recovery password")
                        } catch _ as WrongRecoveryPasswordError {
                            toast = .error("Wrong recovery password")
                        } catch {
                            toast = .error("Error: \(error.localizedDescription)")
                        }
                        loadingPwd = false
                    }
                } label: {
                    if loadingPwd {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Password Recovery")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(loadingPwd)
                .padding(.bottom, 16)

                OrDivider(label: "Or")

                Button {
                    Task {
                        loadingAut = true
                        do {
                            try await handleRecovery(.automatic, nil)
                            toast = .success("Recovery configured successfully!")
                        } catch _ as MissingRecoveryPasswordError {
                            toast = .error("Missing recovery password")
                        } catch _ as WrongRecoveryPasswordError {
                            toast = .error("Wrong recovery password")
                        } catch {
                            toast = .error("Error: \(error.localizedDescription)")
                        }
                        loadingAut = false
                    }
                } label: {
                    if loadingAut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue with Automatic Recovery")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(loadingAut)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .toast($toast)
    }
}

enum RecoveryMethod {
    case password
    case automatic
}

struct MissingRecoveryPasswordError: Error {}
struct WrongRecoveryPasswordError: Error {}
