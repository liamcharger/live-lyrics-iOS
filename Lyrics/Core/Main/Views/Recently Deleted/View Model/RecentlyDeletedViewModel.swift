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
    
    func fetchRecentlyDeletedSongs() {
        self.service.fetchRecentlyDeletedSongs { songs in
            self.songs = songs
            self.isLoadingSongs = false
        }
    }
    
    func deleteSong(song: RecentlyDeletedSong) {
        service.deleteSong(song: song)
    }
    
    func restoreSong(song: RecentlyDeletedSong) {
        service.restoreSong(song: song)
    }
    
    func deleteAllSongs() {
        let group = DispatchGroup()
        
        self.isLoadingSongs = true
        
        for song in songs {
            group.enter()
            self.deleteSong(song: song)
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoadingSongs = false
        }
    }
}
