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
    
    static let shared = SettingsViewModel()
    
    func updateSettings(_ user: User, wordCount: Bool, songSubtitle: String, wordCountStyle: String, showsExplicitSongs: Bool, metronomeStyle: [String], completion: @escaping(Bool, String) -> Void) {
        service.updateSettings(user, wordCount: wordCount, songSubtitle: songSubtitle, wordCountStyle: wordCountStyle, showsExplicitSongs: showsExplicitSongs, metronomeStyle: metronomeStyle) { success, errorMessage in
            if success {
                completion(true, "")
            } else {
                completion(false, errorMessage)
            }
        }
    }
}
