//
//  NotificationManager.swift
//  Lyrics
//
//  Created by Liam Willey on 8/22/23.
//

import Foundation

enum NotificationStatus {
    case updateAvailable
    case collaborationChanges
    case firebaseNotification
}

class NotificationManager: ObservableObject {
    
    init() {
        updateAppVersion()
    }
    
    func getCurrentAppVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let version = (appVersion as! String)
        return version
    }
    
    func checkForUpdate(completion: @escaping(Bool) -> Void) {
        let version = getCurrentAppVersion()
        let savedVersion = UserDefaults.standard.string(forKey: "savedVersion")
        
        if savedVersion == version {
            completion(false)
        } else {
            completion(true)
        }
    }
    
    func updateAppVersion() {
        let version = getCurrentAppVersion()
        UserDefaults.standard.set(version, forKey: "savedVersion")
    }
}
