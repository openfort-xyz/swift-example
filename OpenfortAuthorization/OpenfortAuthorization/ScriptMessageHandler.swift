//
//  ScriptMessageHandler.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-24.
//

import WebKit
import Foundation

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Make sure message.body is a dictionary [String: Any]
        guard let dict = message.body as? [String: Any] else {
            print("Received message is not a dictionary: \(message.body)")
            // Optionally notify user of format error
            return
        }
        
        // Check if success key exists and is a Bool
        guard let success = dict["success"] as? Bool else {
            print("No 'success' key in message or not a Bool: \(dict)")
            return
        }
        
        if success {
            // Handle the 'data' key
            if let data = dict["data"] {
                // TODO: parse data as needed, e.g., convert to model
                print("Received successful data: \(data)")
                // Example: handle data dictionary
                if let dataDict = data as? [String: Any] {
                    // Parse your expected result here
                    // e.g., let result = MyModel(dictionary: dataDict)
                }
            } else {
                print("Success message but no data found: \(dict)")
            }
        } else {
            // Handle the 'error' key
            let errorMsg = dict["error"] as? String ?? "Unknown error"
            print("Received error: \(errorMsg)")
            // Optionally show error to user or handle accordingly
        }
    }
}
