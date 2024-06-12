//
//  RecentlyDeletedViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 4/9/24.
//

import Foundation
import FirebaseAuth
import Firebase
import SwiftUI
import CoreData

class RecentlyDeletedViewModel: ObservableObject {
    @Published var songs: [RecentlyDeletedSong] = []
    @Published var isLoadingSongs = true
    
    let service = SongService()
    
    static let shared = RecentlyDeletedViewModel()
    
    func removeRecentSongEventListener() {
        service.removeRecentSongEventListener()
    }
    
    func fetchRecentlyDeletedSongs() {
        self.service.fetchRecentlyDeletedSongs { songs in
            self.songs = songs
            self.isLoadingSongs = false
        }
    }
    
    func deleteSong(_ folder: Folder, _ song: Song) {
        service.deleteSong(folder, song)
    }
    
    func deleteSong(song: RecentlyDeletedSong) {
        service.deleteSong(song: song)
    }
    
    func deleteSong(_ song: Song) {
        service.deleteSong(song)
    }
    
    func deleteFolder(_ folder: Folder) {
        service.deleteFolder(folder)
    }
    
    func restoreSong(song: RecentlyDeletedSong) {
        service.restoreSong(song: song)
    }
}
