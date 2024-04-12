//
//  RecentlyDeletedView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/26/23.
//

import SwiftUI

struct RecentlyDeletedView: View {
    @ObservedObject var recentlyDeletedViewModel = RecentlyDeletedViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @StateObject var authViewModel = AuthViewModel()
    
    @State var text = ""
    
    @State var showMenu = false
    @State var showNewSong = false
    @State var isEditing = false
    
    @State private var selectedSong: RecentlyDeletedSong?
    @State private var showDeleteSheet = false
    
    var searchableSongs: [RecentlyDeletedSong] {
        if text.isEmpty {
            return recentlyDeletedViewModel.songs
        } else {
            let lowercasedQuery = text.lowercased()
            return recentlyDeletedViewModel.songs.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let song = recentlyDeletedViewModel.songs[index]
            recentlyDeletedViewModel.deleteSong(song: song)
        }
    }
    func performAction(for song: RecentlyDeletedSong) {
        selectedSong = song
        showDeleteSheet.toggle()
    }
    
    init() {
        recentlyDeletedViewModel.fetchRecentlyDeletedSongs()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: "Recently Deleted", navType: .RecentlyDeleted, folder: nil, showBackButton: true, isEditing: $isEditing)
                CustomSearchBar(text: $text, imageName: "magnifyingglass", placeholder: "Search")
            }
            .padding()
            Divider()
            ScrollView {
                VStack {
                    if storeKitManager.purchasedProducts.isEmpty {
                        AdBannerView(unitId: "ca-app-pub-5671219068273297/5562143788", height: 70)
                            .padding(.bottom, 10)
                    }
                    if !recentlyDeletedViewModel.isLoadingSongs {
                        Text("Deleted songs are stored for thirty days before being permanently removed.")
                            .foregroundColor(Color.gray)
                            .deleteDisabled(true)
                        ForEach(searchableSongs, id: \.id) { song in
                            if song.title == "noSongs" {
                                Text("No Songs")
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .cornerRadius(20)
                                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
                            } else {
                                let songData = Song(id: song.id ?? "", uid: song.uid, timestamp: song.timestamp, title: song.title, lyrics: song.lyrics, order: song.order)
                                
                                NavigationLink(destination: SongDetailView(song: songData, songs: nil, restoreSong: song, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", folder: nil), label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(song.title)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        Text("\(song.deletedTimestamp.formatted())").foregroundColor(Color.gray)
                                    }
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .cornerRadius(20)
                                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
                                    .contextMenu {
                                        Button {
                                            selectedSong = song
                                            if selectedSong?.folderId != nil {
                                                recentlyDeletedViewModel.restoreSongToFolder(song: selectedSong!)
                                            } else {
                                                recentlyDeletedViewModel.restoreSong(song: selectedSong!)
                                            }
                                            recentlyDeletedViewModel.fetchRecentlyDeletedSongs()
                                        } label: {
                                            Label("Restore", systemImage: "clock.arrow.circlepath")
                                        }
                                        
                                        Button(role: .destructive) {
                                            performAction(for: song)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                })
                            }
                        }
                    } else {
                        LoadingView()
                    }
                }
                .padding(.top)
                .padding(.horizontal)
                .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
                    if let selectedSong = selectedSong {
                        Button("Delete", role: .destructive) {
                            print("Deleting song: \(selectedSong.title)")
                            recentlyDeletedViewModel.deleteSong(song: selectedSong)
                            recentlyDeletedViewModel.fetchRecentlyDeletedSongs()
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                } message: {
                    if let selectedSong = selectedSong {
                        Text("Are you sure you want to permanently delete \"\(selectedSong.title)\"?")
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RecentlyDeletedView()
}
