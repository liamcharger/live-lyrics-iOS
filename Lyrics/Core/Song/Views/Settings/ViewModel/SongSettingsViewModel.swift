//
//  SongSettingsViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 10/24/23.
//

import Foundation
import SwiftUI

class SongSettingsViewModel: ObservableObject {
    @Published var duration = ""
    @Published var enableAutoscroll = true
    
    let service = SongService()
    
    func updateSongSettings(songId: String, duration: String, completion: @escaping(Bool) -> Void) {
        service.updateSongSettings(songId: songId, duration: duration) { success in
            if success {
                completion(true)
            } else {
                completion(false)
                print("There was an error updating the song settings.")
            }
        }
    }
    
    func updateAutoscrollBool(songId: String, autoscrollEnabled: Bool, completion: @escaping(Bool) -> Void) {
        service.updateAutoscrollBool(songId: songId, autoscrollEnabled: autoscrollEnabled) { success in
            if success {
                completion(true)
            } else {
                completion(false)
                print("There was an error updating the song settings.")
            }
        }
    }
    
    func readSongSettings(songId: String) {
        service.fetchSongSettings(withId: songId) { duration in
            self.duration = duration
        }
    }
    
    func fetchSong(songId: String, completion: @escaping(Song) -> Void) {
        service.fetchSong(withId: songId) { song in
            completion(song)
        }
    }
}
