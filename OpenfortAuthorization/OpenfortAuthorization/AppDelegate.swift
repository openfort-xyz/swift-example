//
//  AppDelegate.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-24.
//

import UIKit
import OpenfortSwift

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do {
            try OFSDK.setupSDK()
        } catch {
            print("Unable to setup Openfort SDK: \(error.localizedDescription)")
        }

        return true
    }
}
