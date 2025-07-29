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


struct ContentView: View {
    
    @State private var username: String = "testing@fort.dev"
    @State private var password: String = "B3sF!JxJD3@727q"
    @State private var isLoggedIn = false
    
    private let openfort = OFSDK.shared
    
    @State private var handle: AuthStateDidChangeListenerHandle?
    @State private var authProvider: String?
    
    @State private var webViewRef: WKWebView?
    var body: some View {
        Group {
            if isLoggedIn {
                LoggedInView(email: username, authProvider: authProvider ?? "", onLogout: {
                    self.isLoggedIn = false
                })
            } else {
                VStack(spacing: 20.0) {
                    Text("Login & Signup")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 4)
                    Text("Enter an email and password below and either sign in to an existing account or sign up")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Username", text: $username)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    SecureField("Password", text: $password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    Button("Sign In") {
                        signIn()
                    }
                    Button("Sign Up") {
                        signUp()
                    }
                    Button("Firebase Sign In") {
                        firebaseSignIn()
                    }
                    Button("Firebase Sign Up") {
                        firebaseSignUp()
                    }
                }.padding(10.0)
            }
        }.onAppear {
            handle = Auth.auth().addStateDidChangeListener { auth, user in
                if user != nil {
                    handleFirebaseAuth(user!)
                }
            }
        }.onDisappear {
            Auth.auth().removeStateDidChangeListener(handle!)
        }
    }
    
    func signIn() {
        let username = self.username
        let password = self.password
        let params = OFAuthEmailPasswordParams(email: username, password: password)
        openfort.loginWith(params: params, completion: { result in
            switch result {
            case .success(let authResponse):
                processAuthResponse(authResponse)
            case .failure(let error):
                break
            }
        })
    }
    
    func signUp() {
        let username = self.username
        let password = self.password
        let params = OFSignUpWithEmailPasswordParams(email: username, password: password)
        openfort.signUpWith(params: params, completion: { result in
            switch result {
            case .success(let signUpResponse):
                processSignUpResponse(signUpResponse)
            case .failure(let error):
                break
            }
        })
    }
    
    func firebaseSignIn() {
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if error == nil {
                if let user = authResult?.user {
                    handleFirebaseAuth(user)
                }
            }
        }
    }
    
    private func handleFirebaseAuth(_ user: User) {
        user.getIDToken(completion: { idToken, error in
            if let idToken = idToken {
                if openfort.isInitialized {
                    processThirdPatyAuth(idToken)
                } else {
                    openfort.didLoad = {
                        processThirdPatyAuth(idToken)
                    }
                }
            } else {
                print("Failed to get idToken: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
    }
    
    private func processThirdPatyAuth(_ idToken: String) {
        let params = OFAuthenticateWithThirdPartyProviderParams(provider: "firebase", token: idToken, tokenType: "idToken")
        openfort.authenticateWithThirdPartyProvider(params: params, completion: { result in
            authProvider = "firebase"
            isLoggedIn = true
        })
    }
    
    func firebaseSignUp() {
        Auth.auth().createUser(withEmail: username, password: password) { authResult, error in
            
        }
    }
    
    private func processAuthResponse(_ response: OFAuthorizationResponseProtocol) {
        OFUser.shared.update(from: response)
        self.isLoggedIn = true
    }
    
    private func processSignUpResponse(_ response: OFSignUpResponseProtocol) {
        
    }
    
    var contentUrl: URL {
        Bundle.main.url(forResource: "index", withExtension: "html")!
    }
}

#Preview {
    ContentView()
}
