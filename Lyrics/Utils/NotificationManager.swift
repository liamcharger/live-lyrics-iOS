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
    case network
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func getCurrentAppVersion() -> String {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return ""
        }
        return appVersion
    }
    
    func checkForUpdate(completion: @escaping (Bool) -> Void) {
        let version = getCurrentAppVersion()
        let savedVersion = UserDefaults.standard.string(forKey: "savedVersion")
        
        completion(savedVersion != version)
    }
    
    func updateAppVersion() {
        let version = getCurrentAppVersion()
        UserDefaults.standard.set(version, forKey: "savedVersion")
    }
}
