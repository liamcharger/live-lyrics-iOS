//
//  SongDetailViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import Foundation
import SwiftUI

class SongViewModel: ObservableObject {
    @ObservedObject var mainViewModel = MainViewModel()
    let service = SongService()
    
    func createSong(folder: Folder, lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
        service.createSong(folder: folder, lyrics: lyrics, title: title) { success, errorMessage in
            if success {
                self.mainViewModel.fetchSongs(folder)
                completion(true, "Success!")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func createSong(lyrics: String, title: String, completion: @escaping(Bool, String) -> Void) {
        service.createSong(lyrics: lyrics, title: title) { success, errorMessage in
            if success {
                self.mainViewModel.fetchSongs()
                completion(true, "Success!")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func addSongToMySongs(id: String, lyrics: String, title: String, artist: String?, timestamp: Date, key: String?, bpm: String?, completion: @escaping(Bool, String) -> Void) {
        service.addSongToMySongs(id: id, lyrics: lyrics, title: title, artist: artist, timestamp: timestamp, key: key, bpm: bpm) { success, errorMessage in
            if success {
                completion(true, "Success!")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func moveSongsToFolder(folder: Folder, songs: [Song], completion: @escaping(Bool, String) -> Void) {
        service.moveSongsToFolder(toFolder: folder, songs: songs) { success, errorMessage in
            if success {
                completion(true, "")
            } else {
                completion(false, errorMessage)
            }
        }
    }
    
    func createFolder(title: String, completionBool: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        service.createFolder(title: title) { success in
            if success {
                self.mainViewModel.fetchFolders()
                completionBool(true)
            } else {
                completionBool(false)
            }
        } completionString: { string in
            completionString(string)
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
    
    func fetchSong(_ id: String, completion: @escaping(Song) -> Void) {
        service.fetchSong(withId: id) { song in
            completion(song)
        }
    }
    
    func updateTitle(_ song: Song, title: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.updateTitle(song: song, title: title) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { string in
                completionString(string)
            }
        }
    }
    
    func updateDuration(_ song: Song, duration: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.updateDuration(song: song, duration: duration) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { string in
                completionString(string)
            }
        }
    }
    
    func updateArtist(_ song: Song, artist: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.updateArtist(song: song, artist: artist) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { string in
                completionString(string)
            }
        }
    }
    
    func updateKey(_ song: Song, key: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
            self.service.updateKey(song: song, key: key) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { string in
                completionString(string)
            }
    }
    
    func updateTitle(_ folder: Folder, title: String, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.updateTitle(folder: folder, title: title) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { string in
                completionString(string)
            }
        }
    }
    
    func moveSongToFolder(fromFolder: Folder, toFolder: Folder, _ song: Song, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.moveSongToFolder(currentFolder: fromFolder, toFolder: toFolder, song: song) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { error in
                completionString(error)
            }

        }
    }
    
    func moveSongToFolder(toFolder: Folder, _ song: Song, completion: @escaping(Bool) -> Void, completionString: @escaping(String) -> Void) {
        DispatchQueue.main.async {
            self.service.moveSongToFolder(toFolder: toFolder, song: song) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            } completionString: { error in
                completionString(error)
            }

        }
    }
    
    func moveSongToRecentlyDeleted(_ song: Song) {
        DispatchQueue.main.async {
            self.service.moveSongToRecentlyDeleted(song: song) { success in
                if success {
                    self.mainViewModel.fetchSongs()
                } else {
                    
                }
            } completionString: { string in
                
            }
        }
    }
    
    func moveSongToRecentlyDeleted(_ folder: Folder, _ song: Song) {
        DispatchQueue.main.async {
            self.service.moveSongToRecentlyDeleted(folder: folder, song: song) { success in
                if success {
                    
                } else {
                    
                }
            } completionString: { string in
                
            }
        }
    }
    
    func fetchSongPinStatus(_ song: Song, completion: @escaping(Bool) -> Void) {
        service.fetchSong(withId: song.id ?? "") { song in
            completion(song.pinned ?? false)
        }
    }
    
    func pinSong(_ song: Song) {
        service.pinSong(song)
    }
    
    func unpinSong(_ song: Song) {
        service.unpinSong(song)
    }
}
