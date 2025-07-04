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
    private let coordinator = WebViewCoordinator()
    private let messageHandler = ScriptMessageHandler()
    private let openfort = OFSDK()
    
    @State private var webViewRef: WKWebView?
    var body: some View {
        VStack(spacing: 10.0) {
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
            WebView(url: contentUrl,
                    delegate: coordinator,
                    scriptMessageHandler: messageHandler,
                    onWebViewCreated: { wkWebView  in
                self.webViewRef = wkWebView
            }).hidden()
        }
    }
    
    func signIn() {
        let username = self.username  // your @State vars
        let password = self.password
        openfort.loginWith(username, password)
    }
    
    func signUp() {

    }
    
    var contentUrl: URL {
        Bundle.main.url(forResource: "index", withExtension: "html")!
    }
}

#Preview {
    ContentView()
}
