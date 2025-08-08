//
//  ContentView.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import SwiftUI
import JavaScriptCore
import WebKit
import OpenfortSwift
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct LoginView: View {
    
    @State private var email: String = "testing@fort.dev"
    @State private var password: String = "B3sF!JxJD3@727q"
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showResetPassword = false
    @State private var showSignUp = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isSignedIn = false
    @State private var showConnectWallet = false
    @StateObject private var homeViewModel = HomeViewModel()
    private let openfort = OFSDK.shared
    
    var body: some View {
        NavigationView {
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
                                        .autocapitalization(.none)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Password")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        if showPassword {
                                            TextField("Password", text: $password)
                                                .autocapitalization(.none)
                                        } else {
                                            SecureField("Password", text: $password)
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
                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {
                                        showResetPassword = true
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
                            
                            Button(action: {
                                Task {
                                    await continueAsGuest()
                                }
                            }) {
                                Text("Continue as Guest")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                            }
                            .padding(.top, 12)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("Or continue with")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.vertical, 16)
                            
                            // Social buttons
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    socialButton("Continue with Google", icon: "globe") { continueWithGoogle() }
                                    socialButton("Continue with Twitter", icon: "bird") { continueWithTwitter() }
                                }
                                HStack(spacing: 8) {
                                    socialButton("Continue with Facebook", icon: "f.square") { continueWithFacebook() }
                                    socialButton("Continue with Wallet", icon: "wallet.pass") { continueWithWallet() }
                                }
                            }
                            
                            HStack {
                                Text("Don’t have an account?")
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
                    
                    // Toast
                    if showToast {
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .transition(.move(edge: .top))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showToast = false }
                                }
                            }
                            .zIndex(2)
                    }
                }
                // Modals
                .sheet(isPresented: $showResetPassword) {
                    ResetPasswordView(email: email)
                }
                .sheet(isPresented: $showSignUp) {
                    RegisterView()
                }
                .sheet(isPresented: $showConnectWallet) {
                    ConnectWalletView(onSignIn: {
                        showConnectWallet = false
                    })
                }
            } else {
                HomeView(viewModel: homeViewModel).onAppear {
                    homeViewModel.onLogout = {
                        isSignedIn = false
                        toastMessage = "Sigend Out!"
                        showToast = true
                    }
                }
            }
        }
    }
    
    func signIn() async {
        isLoading = true
        let username = self.email
        let password = self.password
        
        do {
            let result = try await Auth.auth().signIn(withEmail: username, password: password)
            await authoriseToOpenfortWith(result, message: "Signed in!")
        } catch {
            toastMessage = "Failed to sign in: \(error.localizedDescription)"
            isLoading = false
            showToast = true
            return
        }
    }
    
    func continueAsGuest() async {
        isLoading = true
        do {
            let signUpResponse = try await openfort.signUpGuest()
            isSignedIn = true
            toastMessage = "Signed in as Guest!"
        } catch {
            toastMessage = "Failed to sign in as Guest: \(error.localizedDescription)"
        }
        isLoading = false
        showToast = true
    }
    
    func continueWithGoogle() {
        isLoading = true
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            toastMessage = "Missing Google client ID"
            showToast = true
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            toastMessage = "Unable to get rootViewController"
            showToast = true
            return
        }
        GIDSignIn.sharedInstance.configuration = config
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: nil, completion:{ signInResult, error in
            isLoading = false
            if let error = error {
                toastMessage = "Google Sign-In failed: \(error.localizedDescription)"
                showToast = true
                return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                toastMessage = "Failed to get Google ID Token"
                showToast = true
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    toastMessage = "Firebase Auth failed: \(error.localizedDescription)"
                    showToast = true
                } else {
                    Task {
                        await authoriseToOpenfortWith(authResult, message: "Signed in with Google!")
                    }
                }
            }
        } )
    }
    
    func continueWithTwitter() {
        isLoading = true
        let provider = OAuthProvider(providerID: "twitter.com")
        provider.getCredentialWith(nil) { credential, error in
            isLoading = false
            if let error = error {
                toastMessage = "Twitter Sign-In failed: \(error.localizedDescription)"
                showToast = true
                return
            }
            guard let credential = credential else {
                toastMessage = "Failed to get Twitter credential"
                showToast = true
                return
            }
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    toastMessage = "Firebase Auth failed: \(error.localizedDescription)"
                    showToast = true
                } else {
                    Task {
                        await authoriseToOpenfortWith(authResult, message: "Signed in with Twitter!")
                    }
                }
            }
        }
    }
    
    func continueWithFacebook() {
        isLoading = true
        let provider = OAuthProvider(providerID: "facebook.com")
        provider.getCredentialWith(nil) { credential, error in
            if let error = error {
                isLoading = false
                toastMessage = "Facebook Sign-In failed: \(error.localizedDescription)"
                showToast = true
                return
            }
            guard let credential = credential else {
                toastMessage = "Failed to get Facebook credential"
                showToast = true
                return
            }
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    isLoading = false
                    toastMessage = "Firebase Auth failed: \(error.localizedDescription)"
                    showToast = true
                } else {
                    Task {
                        await authoriseToOpenfortWith(authResult, message: "Signed in with Facebook!")
                    }
                }
            }
        }
    }
    
    func continueWithWallet() {
        showConnectWallet = true
    }
    
    func socialButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
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
    
    private func authoriseToOpenfortWith(_ result: AuthDataResult?, message: String) async {
        
        guard let authResult = result else {
            fatalError("Unexpected nil authResult")
        }
        do {
            let token = try await authResult.user.getIDToken()
            let authResponse = try await openfort.authenticateWithThirdPartyProvider(params: OFAuthenticateWithThirdPartyProviderParams(provider: "firebase", token: token, tokenType: "idToken"))
            isLoading = false
            toastMessage = message
            showToast = true
            isSignedIn = true
            
        } catch {
            isLoading = false
            toastMessage = "Openfort Auth failed: \(error.localizedDescription)"
            showToast = true
            return
        }
        
    }
    
    private var contentUrl: URL {
        Bundle.main.url(forResource: "index", withExtension: "html")!
    }
}

#Preview {
    LoginView()
}
