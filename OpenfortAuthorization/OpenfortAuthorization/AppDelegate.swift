//
//  AppDelegate.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-24.
//

import UIKit
import FirebaseCore
import OpenfortSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OFSDK.setupSDK()
        FirebaseApp.configure()
        return true
    }
}
