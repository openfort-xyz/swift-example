//
//  WebView.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-22.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let delegate: WKNavigationDelegate?
    let scriptMessageHandler: WKScriptMessageHandler?
    
    var onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView  {
        // Configure webpage preferences for JavaScript
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true

        // Configure the user content controller (message handler for JS-to-Swift bridge)
        let userContentController = WKUserContentController()
        if let messageHandler = scriptMessageHandler {
            userContentController.add(messageHandler, name: "userHandler")
        }

        // Configure the web view
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = webPagePreferences
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        config.userContentController = userContentController

        let wkWebView = WKWebView(frame: .zero, configuration: config)
        wkWebView.navigationDelegate = delegate

        // Load the local file URL
        wkWebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        // Provide the created web view to any observer
        DispatchQueue.main.async {
            onWebViewCreated?(wkWebView)
        }

        return wkWebView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
