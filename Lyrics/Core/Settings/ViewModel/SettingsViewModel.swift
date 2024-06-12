//
//  ProfileViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/19/23.
//

import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    let service = UserService()
    @Published var user: User
    
    init(user: User) {
        self.user = user
        self.fetchUser(withUid: user.id ?? "")
    }
    
    func updateSettings(_ user: User, wordCount: Bool, data: String, wordCountStyle: String, enableAutoscroll: Bool, showsExplicitSongs: Bool, metronomeStyle: [String], completion: @escaping(Bool, String) -> Void) {
        service.updateSettings(user, wordCount: wordCount, data: data, wordCountStyle: wordCountStyle, showsExplicitSongs: showsExplicitSongs, enableAutoscroll: enableAutoscroll, metronomeStyle: metronomeStyle) { success, errorMessage in
            if success {
                completion(true, "")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func fetchUser(withUid uid: String) {
        service.fetchUser(withUid: uid) { user in
            self.user = user
        }
    }
}
