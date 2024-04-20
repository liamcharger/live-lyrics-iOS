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
    @Published var recentlyDeletedSongs: [RecentlyDeletedSong] = []
    @Published var folders: [Folder] = []
    @Published var incomingShareRequests: [ShareRequest] = []
    @Published var outgoingShareRequests: [ShareRequest] = []
    @Published var isLoadingFolders = true
    @Published var isLoadingFolderSongs = true
    @Published var isLoadingSongs = true
    @Published var isLoadingRecentlyDeletedSongs = true
    @Published var isLoadingInvites = false
    
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
            self.folderSongs = songs
            self.isLoadingFolderSongs = false
        }
    }
    
    func fetchSongs() {
        self.service.fetchSongs() { songs in
            self.songs = songs
            self.isLoadingSongs = false
        }
    }
    
    func fetchRecentlyDeletedSongs() {
        self.service.fetchRecentlyDeletedSongs { songs in
            self.recentlyDeletedSongs = songs
            self.isLoadingRecentlyDeletedSongs = false
        }
    }
    
    func fetchNotificationStatus() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "remote_config_defaults")
        
        remoteConfig.fetch { [weak self] _, error in
            if let error = error {
                print("Error fetching remote config: \(error.localizedDescription)")
                return
            }
            
            self?.remoteConfig.activate { _, _ in }
            
            guard let remoteVersionString = self?.remoteConfig.configValue(forKey: "currentVersion").stringValue,
                  let currentVersionString = self?.notificationManager.getCurrentAppVersion() else {
                print("Error: Unable to retrieve version strings")
                return
            }
            
            if let remoteVersion = Version(remoteVersionString), let currentVersion = Version(currentVersionString) {
                if remoteVersion > currentVersion {
                    self?.notificationStatus = .updateAvailable
                }
            }
        }
    }
    
    func fetchFolders() {
        DispatchQueue.main.async {
            self.service.fetchFolders { folders in
                self.folders = folders
                self.isLoadingFolders = false
            }
        }
    }
    
    func updateLyrics(forVariation variation: SongVariation? = nil, _ song: Song, lyrics: String) {
        self.service.updateLyrics(forVariation: variation, song: song, lyrics: lyrics)
    }
    
    func updateSongOrder() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let batch = Firestore.firestore().batch()
        for(index, song) in songs.enumerated() {
            let songRef = Firestore.firestore().collection("users").document(uid).collection("songs").document(song.id ?? "")
            batch.updateData(["order": index], forDocument: songRef)
        }
        batch.commit() { error in
            if let error = error {
                print("Error updating order in Firestore: \(error.localizedDescription)")
            } else {
                print("Order updated in Firestore")
            }
        }
    }
    
    func updateSongOrder(folder: Folder) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let batch = Firestore.firestore().batch()
        for(order, song) in folderSongs.enumerated() {
            guard let songId = song.id else { continue }
            
            let songRef = Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("folders")
                .document(folder.id ?? "")
                .collection("songs")
                .document(songId)
            
            batch.updateData(["order": order], forDocument: songRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error updating order in Firestore: \(error.localizedDescription)")
            } else {
                print("Order updated in Firestore")
            }
        }
    }
    
    func updateFolderOrder() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let batch = Firestore.firestore().batch()
        for(index, folder) in folders.enumerated() {
            let folderRef = Firestore.firestore().collection("users").document(uid).collection("folders").document(folder.id ?? "")
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
    
    func fetchInvites() {
        self.isLoadingInvites = true
        service.fetchIncomingInvites { incomingShareRequests in
            self.incomingShareRequests = incomingShareRequests
        }
        service.fetchOutgoingInvites { outgoingShareRequests in
            self.outgoingShareRequests = outgoingShareRequests
        }
        self.isLoadingInvites = false
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
}
