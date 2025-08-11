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
        
        if let config = OFConfig.load(from: getConfigData()) {
            OFSDK.setupSDK(config: config)
        }
        
        FirebaseApp.configure()
        return true
    }
    
    private func getConfigData() -> Data? {
        if let url = Bundle.main.url(forResource: "OFConfig", withExtension: "plist") {
            return try? Data(contentsOf: url)
        }
        return nil
    }
}
