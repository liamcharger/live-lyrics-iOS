//
//  PersistenceController.swift
//  Lyrics
//
//  Created by Liam Willey on 8/31/23.
//

import SwiftUI

struct PersistenceController {
    @ObservedObject var mainViewModel = MainViewModel()
    
    func loadLocalUser() -> User? {
        let defaults = UserDefaults.standard
        
        if let savedLocalUser = defaults.object(forKey: "localUser") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocalUser = try? decoder.decode(User.self, from: savedLocalUser) {
                return loadedLocalUser
            }
        }
        
        print("Couldn't decode LocalUser object...")
        return nil
    }
    
    func loadLocalSongs() -> [Song]? {
        let defaults = UserDefaults.standard
        
        if let savedLocalSong = defaults.object(forKey: "localSongs") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocalSongs = try? decoder.decode([Song].self, from: savedLocalSong) {
                return loadedLocalSongs
            }
        }
        
        print("Couldn't decode local Song objects...")
        return nil
    }
    
    func loadLocalFolders() -> [Folder]? {
        let defaults = UserDefaults.standard
        
        if let savedLocalFolder = defaults.object(forKey: "localSongs") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocalFolders = try? decoder.decode([Folder].self, from: savedLocalFolder) {
                return loadedLocalFolders
            }
        }
        
        print("Couldn't decode local Folder objects...")
        return nil
    }
    
    func loadLocalRecentlyDeletedSongs() -> [RecentlyDeletedSong]? {
        let defaults = UserDefaults.standard
        
        if let savedLocalRecentlyDeletedSongs = defaults.object(forKey: "localRecentlyDeletedSongs") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocalRecentlyDeletedSongs = try? decoder.decode([RecentlyDeletedSong].self, from: savedLocalRecentlyDeletedSongs) {
                return loadedLocalRecentlyDeletedSongs
            }
        }
        
        print("Couldn't decode local Folder objects...")
        return nil
    }
    
    func saveLocalUser(user: User) {
        mainViewModel.fetchFolders()
        mainViewModel.fetchSongs()
        mainViewModel.fetchRecentlyDeletedSongs()
        
        var localFolders: [Folder] = []
        var localFolderSongs: [DocID] = []
        var localSongs: [Song] = []
        var localRecentlyDeletedSongs: [RecentlyDeletedSong] = []
        
        for folder in mainViewModel.folders {
            mainViewModel.fetchSongs(folder)
            var localSongs: [DocID] = []
            let folderSongs = mainViewModel.folderSongs
            
            for folderSong in folderSongs {
                localSongs.append(DocID(id: folderSong.id, order: folderSong.order ?? 0, folderId: folder.id ?? ""))
            }
            
            let localFolder = Folder(
                id: folder.id ?? "",
                uid: folder.uid,
                timestamp: folder.timestamp, 
                title: folder.title,
                order: folder.order
            )
            
            localFolders.append(localFolder)
            localFolderSongs += localFolderSongs
        }
        
        for song in mainViewModel.songs {
            localSongs.append(song)
        }
        
        for song in mainViewModel.recentlyDeletedSongs {
            localRecentlyDeletedSongs.append(song)
        }
        
        let localUser = User(
            id: user.id,
            email: user.email,
            username: user.username,
            fullname: user.fullname,
            password: user.password,
            wordCount: user.wordCount,
            showDataUnderSong: user.showDataUnderSong,
            wordCountStyle: user.wordCountStyle,
            hasSubscription: user.hasSubscription,
            hasCollapsedPremium: user.hasCollapsedPremium,
            currentVersion: user.currentVersion,
            showsExplicitSongs: user.showsExplicitSongs,
            enableAutoscroll: user.enableAutoscroll
        )
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(localUser) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "localUser")
        }
        if let encoded = try? encoder.encode(localSongs) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "localSongs")
        }
        if let encoded = try? encoder.encode(localFolders) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "localFolders")
        }
        if let encoded = try? encoder.encode(localFolderSongs) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "localFolderSongs")
        }
        if let encoded = try? encoder.encode(localRecentlyDeletedSongs) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "localRecentlyDeletedSongs")
        }
        
        print(localUser, localSongs, localFolders, localFolderSongs)
    }
}

