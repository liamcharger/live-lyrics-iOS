//
//  SongDetailViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class SongViewModel: ObservableObject {
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    @Published var isLoadingVariations = false
    
    let service = SongService()
    static let shared = SongViewModel()
    
    func fetchSongVariations(song: Song, completion: @escaping([SongVariation]) -> Void) {
        service.removeSongVariationListener()
        self.isLoadingVariations = true
        service.fetchSongVariations(song: song) { variations in
            completion(variations)
            self.isLoadingVariations = false
        }
    }
    
    func createSong(folder: Folder, lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
        service.createSong(folder: folder, lyrics: lyrics, title: title) { success, errorMessage in
            if success {
                completion(true, "Success!")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func createSong(lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
        service.createSong(lyrics: lyrics, title: title) { success, errorMessage in
            if success {
                completion(true, "Success!")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func createSongVariation(song: Song, lyrics: String, title: String, role: BandRole?, completion: @escaping(Error?, String) -> Void) {
        service.createSongVariation(song: song, lyrics: lyrics, title: title, role: role) { error, createdId in
            completion(error, createdId)
        }
    }
    
    func moveSongsToFolder(folder: Folder, songs: [Song], completion: @escaping(Error?) -> Void) {
        service.moveSongsToFolder(id: folder.id ?? "", songs: songs) { error in
            completion(error)
        }
    }
    
    func createFolder(title: String, completion: @escaping(Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let folder = Folder(uid: uid, timestamp: Date(), title: title, order: 0)
        
        service.createFolder(folder: folder) { error in
            completion(error)
        }
    }
    
    func updateTextProperties(_ folder: Folder, _ song: Song, size: Int) {
        service.updateTextProperties(folder: folder, song: song, size: size)
    }
    
    func updateTextProperties(_ song: Song, size: Int) {
        service.updateTextProperties(song: song, size: size)
    }
    
    func updateTextProperties(_ song: Song, lineSpacing: Double) {
        service.updateTextProperties(song: song, lineSpacing: lineSpacing)
    }
    
    func updateTextProperties(_ song: Song, weight: Double) {
        service.updateTextProperties(song: song, weight: weight)
    }
    
    func updateTextProperties(_ song: Song, design: Double) {
        service.updateTextProperties(song: song, design: design)
    }
    
    func updateTextProperties(_ song: Song, alignment: Double) {
        service.updateTextProperties(song: song, alignment: alignment)
    }
    
    func fetchSongDetails(_ song: Song, completion: @escaping(String, String, String, String) -> Void) {
        service.fetchEditDetails(song) { title, key, artist, duration in
            completion(title, key, artist, duration)
        }
    }
    
    func fetchSong(listen: Bool? = nil, forUser: String? = nil, _ id: String, completion: @escaping(Song) -> Void, regCompletion: @escaping(ListenerRegistration?) -> Void) {
        service.fetchSong(listen: listen, forUser: forUser, withId: id) { song in
            if let song = song {
                completion(song)
            }
        } registrationCompletion: { reg in
            regCompletion(reg)
        }
    }
    
    func updateTitle(_ folder: Folder, title: String, completion: @escaping(Bool, String) -> Void) {
        service.updateTitle(folder: folder, title: title) { success, errorMessage in
            if success {
                completion(true, "")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func updateSong(_ song: Song, title: String, key: String, artist: String, duration: String, completion: @escaping(Bool, String) -> Void) {
        service.updateSong(song, title: title, key: key, artist: artist, duration: duration) { success, errorMessage in
            completion(success, errorMessage)
        }
    }
    
    func updateBpm(for song: Song, with bpm: Int) {
        service.updateBpm(song: song, bpm: bpm)
    }
    
    func updateBpb(for song: Song, with bpb: Int) {
        service.updateBpb(song: song, bpb: bpb)
    }
    
    func updatePerformanceMode(for song: Song, with performanceMode: Bool) {
        service.updatePerformanceMode(song: song, performanceMode: performanceMode)
    }
    
    func moveSongToRecentlyDeleted(_ song: Song) {
        DispatchQueue.main.async {
            self.service.moveSongToRecentlyDeleted(song: song) { success, errorMessage in
                
            }
        }
    }
    
    func moveSongToRecentlyDeleted(_ folder: Folder, _ song: Song) {
        DispatchQueue.main.async {
            self.service.moveSongToRecentlyDeleted(song: song, from: folder) { success, errorMessage in
                
            }
        }
    }
    
    func pinSong(_ song: Song) {
        service.pinSong(song)
    }
    
    func unpinSong(_ song: Song) {
        service.unpinSong(song)
    }
    
    func updateTagsForSong(_ song: Song, tags: [TagSelectionEnum]) {
        service.updateTagsForSong(song, tags: tags) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func deleteSongVariation(_ song: Song, variation: SongVariation) {
        service.deleteVariation(song: song, variation: variation)
    }
    
    func updateVariation(song: Song, variation: SongVariation, title: String, role: BandRole?) {
        service.updateVariation(song: song, variation: variation, title: title, role: role)
    }
    
    func leaveSong(forUid: String? = nil, song: Song) {
        service.leaveCollabSong(forUid: forUid, song: song) {}
    }
    
    func getColorForTag(_ tagColor: String) -> Color {
        switch tagColor {
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "gray":
            return .gray
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "none":
            return .clear
        default:
            return .gray
        }
    }
    
    func isShared(song: Song) -> Bool {
        return song.uid != authViewModel.currentUser?.id
    }
}
