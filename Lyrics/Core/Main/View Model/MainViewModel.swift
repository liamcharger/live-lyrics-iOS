//
//  MainViewModel.swift
//  Lyrics
//
//  Created by Liam Willey on 5/4/23.
//

import Foundation
import FirebaseAuth
import Firebase
import SwiftUI
import CoreData

class MainViewModel: ObservableObject {
    let notificationManager = NotificationManager.shared
    var remoteConfig: RemoteConfig!
    
    @Published var songs: [Song] = []
    @Published var folderSongs: [Song] = []
    @Published var sharedSongs: [Song] = []
    @Published var sharedFolders: [Folder] = []
    @Published var recentlyDeletedSongs: [RecentlyDeletedSong] = []
    @Published var folders: [Folder] = []
    @Published var incomingShareRequests: [ShareRequest] = []
    @Published var outgoingShareRequests: [ShareRequest] = []
    @Published var selectedFolder: Folder?
    @Published var isLoadingFolders = true
    @Published var isLoadingFolderSongs = true
    @Published var isLoadingSongs = true
    @Published var isLoadingRecentlyDeletedSongs = true
    @Published var isLoadingInvites = true
    @Published var isLoadingSharedSongs = true
    @Published var isLoadingSharedFolders = true
    @Published var isLoadingSharedMedia = true
    
    @Published var systemDoc: SystemDoc?
    
    @Published var notificationStatus: NotificationStatus?
    @Published var notification: Notification?
    
    let service = SongService()
    let userService = UserService()
    
    static let shared = MainViewModel()
    
    func removeSongEventListener() {
        service.removeSongEventListener()
    }
    
    func removeFolderSongEventListener() {
        service.removeFolderSongEventListener()
    }
    
    func removeFolderEventListener() {
        service.removeFolderEventListener()
    }
    
    func removeRecentSongEventListener() {
        service.removeRecentSongEventListener()
    }
    
    func removeIncomingInviteEventListener() {
        service.removeIncomingInviteEventListener()
    }
    
    func removeOutgoingInviteEventListener() {
        service.removeOutgoingInviteEventListener()
    }
    
    func removeSongVariationListener() {
        service.removeSongVariationListener()
    }
    
    func fetchSystemStatus() {
        userService.fetchSystemDoc { systemDoc in
            self.systemDoc = systemDoc
        }
    }
    
    func receivedNotificationFromFirebase(_ notification: Notification) {
        DispatchQueue.main.async {
            self.notificationStatus = .firebaseNotification
            self.notification = notification
        }
    }
    
    func fetchSongs(_ folder: Folder) {
        self.service.fetchSongs(folder) { songs in
            DispatchQueue.main.async {
                self.folderSongs = songs
                self.isLoadingFolderSongs = false
            }
        }
    }
    
    func fetchSongs() {
        self.service.fetchSongs() { songs in
            DispatchQueue.main.async {
                self.songs = songs
                self.isLoadingSongs = false
            }
        }
    }
    
    func fetchRecentlyDeletedSongs() {
        self.service.fetchRecentlyDeletedSongs { songs in
            DispatchQueue.main.async {
                self.recentlyDeletedSongs = songs
                self.isLoadingRecentlyDeletedSongs = false
            }
        }
    }
    
    func fetchFolders() {
        self.service.fetchFolders { folders in
            DispatchQueue.main.async {
                self.folders = folders
                self.isLoadingFolders = false
            }
        }
    }
    
    func fetchInvites() {
        self.isLoadingInvites = true
        service.fetchIncomingInvites { incomingShareRequests in
            DispatchQueue.main.async {
                self.incomingShareRequests = incomingShareRequests
            }
        }
        service.fetchOutgoingInvites { outgoingShareRequests in
            DispatchQueue.main.async {
                self.outgoingShareRequests = outgoingShareRequests
                self.isLoadingInvites = false
            }
        }
    }
    
    func fetchSharedSongs() {
        self.isLoadingSharedSongs = true
        self.service.fetchSharedSongs { songs in
            DispatchQueue.main.async {
                self.sharedSongs = songs
                self.isLoadingSharedSongs = false
            }
        }
    }
    
    func fetchSharedFolders() {
        self.isLoadingSharedFolders = false
        self.service.fetchSharedFolders { folders in
            DispatchQueue.main.async {
                self.sharedFolders = folders
                self.isLoadingSharedFolders = false
            }
        }
    }
    
    func fetchSharedObject(user: User, song: Song?, folder: Folder?, completion: @escaping(SharedSong?, SharedFolder?) -> Void) {
        self.isLoadingSharedMedia = true
        if let song = song {
            service.fetchSharedSong(user: user, song: song) { song in
                completion(song, nil)
            }
        } else if let folder = folder {
            service.fetchSharedFolder(user: user, folder: folder) { folder in
                completion(nil, folder)
            }
        }
        self.isLoadingSharedMedia = false
    }
    
    func updateSharedMediaReadOnly(user: User, song: Song? = nil, folder: Folder? = nil, readOnly: Bool) {
        guard let uid = user.id else { return }
        
        var id: String {
            if let song = song {
                return song.id ?? ""
            } else if let folder = folder {
                return folder.id ?? ""
            }
            return ""
        }
        var media: String {
            if song != nil {
                return "songs"
            } else if folder != nil {
                return "folders"
            }
            return ""
        }
        
        Firestore.firestore().collection("users").document(uid).collection("shared-\(media)").document(id).updateData(["readOnly": readOnly]) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("ReadOnly: updated successfully")
        }
    }
    
    func fetchNotificationStatus() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "remote_config_defaults")
        
        remoteConfig.addOnConfigUpdateListener { configUpdate, error in
            guard let configUpdate, error == nil else {
                print("Error listening for config updates: \(String(describing: error?.localizedDescription))")
                return
            }
            
            print("Updated keys: \(configUpdate.updatedKeys)")
            
            self.remoteConfig.activate { changed, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    guard let remoteVersionString = self.remoteConfig.configValue(forKey: "currentVersion").stringValue else {
                        return
                    }
                    
                    let remoteVersionComponents = remoteVersionString.split(separator: ".")
                    
                    let currentVersionString = self.notificationManager.getCurrentAppVersion()
                    let currentVersionComponents = currentVersionString.split(separator: ".")
                    
                    for (remoteComponent, currentComponent) in zip(remoteVersionComponents, currentVersionComponents) {
                        guard let remoteNumber = Int(remoteComponent), let currentNumber = Int(currentComponent) else {
                            return
                        }
                        
                        if remoteNumber < currentNumber {
                            self.notificationStatus = .updateAvailable
                            return
                        } else if remoteNumber > currentNumber {
                            return
                        }
                    }
                    
                    if remoteVersionComponents.count < currentVersionComponents.count {
                        self.notificationStatus = .updateAvailable
                    }
                }
            }
        }
    }
    
    func updateLyrics(forVariation variation: SongVariation? = nil, _ song: Song, lyrics: String) {
        self.service.updateLyrics(forVariation: variation, song: song, lyrics: lyrics)
    }
    
//    func updateSongOrder() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        let batch = Firestore.firestore().batch()
//        for(index, song) in songs.enumerated() {
//            if song.uid != uid {
//                let songRef = Firestore.firestore().collection("users").document(uid).collection("shared-songs").document(song.id ?? "")
//                batch.updateData(["order": index], forDocument: songRef)
//            } else {
//                let songRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
//                batch.updateData(["order": index], forDocument: songRef)
//            }
//        }
//        batch.commit() { error in
//            if let error = error {
//                print("Error updating order in Firestore: \(error.localizedDescription)")
//            } else {
//                print("Order updated in Firestore")
//            }
//        }
//    }
    
    func updateSongOrder(folder: Folder) {
        let batch = Firestore.firestore().batch()
        
        guard let folderUid = folder.uid, !folderUid.isEmpty,
              let folderId = folder.id, !folderId.isEmpty else {
            print("Invalid folder UID or ID")
            return
        }
        
        for (index, song) in folderSongs.enumerated() {
            guard let songId = song.id else { continue }
            
            let document = Firestore.firestore()
                .collection("users")
                .document(folderUid)
                .collection("folders")
                .document(folderId)
                .collection("songs")
                .document(songId)
            
            batch.updateData(["order": index], forDocument: document)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error updating song order: \(error.localizedDescription)")
            } else {
                print("Song order updated successfully")
            }
        }
    }
    
    func updateFolderOrder() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let batch = Firestore.firestore().batch()
        for(index, folder) in folders.enumerated() {
            let folderRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id!)
            batch.updateData(["order": index], forDocument: folderRef)
        }
        batch.commit() { error in
            if let error = error {
                print("Error updating order in Firestore: \(error.localizedDescription)")
            } else {
                print("Order updated in Firestore")
            }
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
    
    func declineInvite(incomingReqColUid: String? = nil, request: ShareRequest, completion: @escaping() -> Void) {
        service.declineInvite(incomingReqColUid: incomingReqColUid, request: request) {
            completion()
        }
    }
    
    func acceptInvite(request: ShareRequest, completion: @escaping() -> Void) {
        service.acceptInvite(request: request) {
            completion()
        }
    }
    
    func leaveCollabFolder(forUid: String? = nil, folder: Folder) {
        service.leaveCollabFolder(forUid: forUid, folder: folder) {}
    }
}
