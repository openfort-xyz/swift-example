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

struct ContentView: View {
    
    @State private var username: String = "testing@fort.dev"
    @State private var password: String = "B3sF!JxJD3@727q"
    private let openfort = OFSDK()
    
    @State private var webViewRef: WKWebView?
    var body: some View {
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
        }.padding(10.0)
    }
    
    func signIn() {
        let username = self.username
        let password = self.password
        
        openfort.loginWith(username, password) { result in
            switch result {
            case .success(let authResponse):
                processAuthResponse(authResponse)
            case .failure(let error):
                break
            }
        }
    }
    
    func signUp() {
        let username = self.username
        let password = self.password
        openfort.signUpWith(email: username, password: password, ecosystemGame: nil) { result in
            switch result {
            case .success(let signUpResponse):
                processSignUpResponse(signUpResponse)
            case .failure(let error):
            break
        }
        }
    }
    
    private func processAuthResponse(_ response: OFAuthorizationResponseProtocol) {
        
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
