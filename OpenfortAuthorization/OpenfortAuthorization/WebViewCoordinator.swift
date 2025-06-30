//
//  WebViewCoordinator.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-22.
//
import Foundation
import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ WebView finished loading.")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView failed to load: \(error.localizedDescription)")
    }
}
