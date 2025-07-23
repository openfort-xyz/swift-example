//
//  OpenfortAuthorizationApp.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import SwiftUI
import FirebaseCore

@main
struct OpenfortAuthorizationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
