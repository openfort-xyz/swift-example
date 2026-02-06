//
//  HomeView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var toast: ToastState?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if viewModel.state == .embeddedSignerNotConfigured {
                        VStack(spacing: 18) {
                            Text("Set up your embedded signer")
                                .font(.title2).bold()
                            Text("Welcome, \(viewModel.user?.name ?? viewModel.user?.id ?? "User")!")
                                .foregroundColor(.gray)
                            HStack {
                                Spacer()
                                Button(role: .destructive) {
                                    Task {
                                        await logout()
                                    }
                                } label: {
                                    Label("Logout", systemImage: "arrow.right.square")
                                }
                                .tint(.red)
                            }
                            AccountRecoveryView(handleRecovery: viewModel.handleRecovery)
                        }
                        .cardStyle(shadowRadius: 8)
                        .padding(.vertical, 24)
                    } else if viewModel.state == .creatingAccount {
                        VStack {
                            ProgressView()
                            Text("Creating your account, please wait...")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 80)
                    } else if viewModel.state == .ready {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Welcome, \(viewModel.user?.id ?? "user")!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Button(role: .destructive) {
                                Task {
                                    await logout()
                                }
                            } label: {
                                Label("Logout", systemImage: "arrow.right.square")
                            }
                            .tint(.red)
                            VStack(spacing: 20) {
                                SignaturesPanelView(handleSetMessage: viewModel.handleSetMessage, embeddedState: viewModel.state)
                                LinkedSocialsPanelView(user: viewModel.user, handleSetMessage: viewModel.handleSetMessage)
                                EmbeddedWalletPanelView(handleSetMessage: viewModel.handleSetMessage, viewModel: EmbeddedWalletPanelViewModel(embeddedState: viewModel.state, embeddedAccount: viewModel.embeddedAccount))
                            }
                            .padding(.top, 12)
                        }
                        .padding()
                    }
                    Spacer()
                }
                .frame(maxWidth: 800)
                .padding(.horizontal, 20)
            }

            if viewModel.state != .ready {
                SidebarIntroView(openDocs: openDocs, openDocsLearnMore: openDocsLearnMore)
                    .background(Color(.systemGray6))
            }
        }
        .toast($toast)
        .onChange(of: viewModel.lastMessage) { msg in
            if let msg = msg {
                toast = .result(msg)
                viewModel.lastMessage = nil
            }
        }
    }

    func openDocs() {
        if let url = URL(string: "https://www.openfort.io/docs") {
            UIApplication.shared.open(url)
        }
    }
    func openDocsLearnMore() {
        if let url = URL(string: "https://www.openfort.io/docs/products/embedded-wallet/react/kit/create-react-app") {
            UIApplication.shared.open(url)
        }
    }

    func logout() async {
        await viewModel.logout()
    }
}

struct SidebarIntroView: View {
    let openDocs: () -> Void
    let openDocsLearnMore: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore Openfort")
                    .font(.headline)
                Text("Sign in to the demo to access the dev tools.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Button(action: openDocs) {
                    Text("Explore the Docs")
                }
                .buttonStyle(.bordered)
                .padding(.top, 2)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Openfort gives you modular components so you can customize your product for your users.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Button(action: openDocsLearnMore) {
                    Text("Learn more")
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
}

