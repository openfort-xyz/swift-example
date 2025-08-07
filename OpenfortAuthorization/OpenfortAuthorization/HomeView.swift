//
//  HomeView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift
import Combine
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack {
                        if viewModel.state == .embeddedSignerNotConfigured {
                            VStack(spacing: 18) {
                                Text("Set up your embedded signer")
                                    .font(.title2).bold()
                                Text("Welcome, \(viewModel.user?.displayName ?? viewModel.user?.id ?? "User")!")
                                    .foregroundColor(.gray)
                                // Logout
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
                                // Account recovery component slot
                                AccountRecoveryView(handleRecovery: viewModel.handleRecovery)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                            .padding(.vertical, 24)
                        } else if viewModel.state == .creatingAccount {
                            VStack {
                                ProgressView()
                                if viewModel.state == .creatingAccount {
                                    Text("Creating your account, please wait...")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
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
                                    // Account actions
                                    AccountActionsView(handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Signatures
                                    SignaturesPanelView(handleSetMessage: viewModel.handleSetMessage, embeddedState: viewModel.state)
                                    
                                    // Linked socials
                                    LinkedSocialsPanelView(user: viewModel.user, handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Embedded wallet
                                    EmbeddedWalletPanelView(handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Wallet Connect
                                    WalletConnectPanelView(viewModel: WalletConnectPanelViewModel())
                                    
                                    // Funding
                                    FundingPanelView(handleSetMessage: viewModel.handleSetMessage)
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
                } else {
                    // Console style sidebar
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass") // SF Symbol for wallet
                                .font(.system(size: 18))
                            Text("Console").bold()
                            Spacer()
                        }
                        .padding(8)
                        ZStack {
                            TextEditor(text: $viewModel.message)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .background(Color.gray.opacity(0.12))
                                .cornerRadius(6)
                                .padding(8)
                                .frame(minHeight: 140)
                        }
                    }
                    .background(Color(.systemGray6))
                }
            }
            .toast(isPresented: $showToast, message: toastMessage)
            
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
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Models & Toast

@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: OFEmbeddedState = .none
    @Published var user: UserModel?
    @Published var message: String = ""
    var onLogout: (() -> Void)?
    
    private var cancellable: AnyCancellable?
    
    lazy var handleRecovery: (_ method: RecoveryMethod, _ password: String?) async throws -> Void = { method, password in
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            self.message = "Error fetching ID token.\n\n" + self.message
            return
        }
        let chainId = 80002
        let shield = OFShieldAuthenticationDTO(auth: "openfort", token: token, authProvider: "firebase", tokenType: "idToken")
        do {
            let result = try await OFSDK.shared.configure(params: OFConfigureEmbeddedWalletDTO(chainId: chainId, shieldAuthentication: shield, recoveryParams: OFRecoveryParamsDTO(recoveryMethod: method == .password ? "password" : "automatic", password: password)))
            self.message = "Embedded wallet configured successfully.\n\n" + self.message
        } catch {
            self.message = "Error configuring embedded wallet: \(error)\n\n" + self.message
        }
        
    }
    
    init() {
        self.cancellable = OFSDK.shared.embeddedStatePublisher
            .replaceNil(with: .none)
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
    }
    
    func logout() async {
        do {
            try await OFSDK.shared.logOut()
        } catch let error {
            message = "Error logging out: \(error)\n\n" + message
            return
        }
        onLogout?()
    }
    
    func handleSetMessage(_ msg: String) {
        message = "> \(msg)\n\n" + message
    }
}



extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .top))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
                    .zIndex(2)
            }
        }
    }
}
