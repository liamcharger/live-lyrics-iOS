//
//  SongView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/10/23.
//

import SwiftUI
import BottomSheet

struct AllSongView: View {
    // Object & Environment vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @StateObject var authViewModel = AuthViewModel()
    @Environment(\.presentationMode) var presMode
    
    // State vars
    @State var text = ""
    
    @State var showMenu = false
    @State var showNewSong = false
    @State var isEditing = false
    
    @State private var selectedSong: Song?
    @State private var showMoveSheet = false
    @State private var showDeleteSheet = false
    @State private var showEditSheet = false
    @State private var isShowingUnpinPin = false
    
    // Standard vars
    var searchableSongs: [Song] {
        if text.isEmpty {
            return mainViewModel.songs
        } else {
            let lowercasedQuery = text.lowercased()
            return mainViewModel.songs.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    func move(from source: IndexSet, to destination: Int, folderSongs: [Song]) {
        mainViewModel.songs.move(fromOffsets: source, toOffset: destination)
        mainViewModel.updateSongOrder()
        mainViewModel.fetchSongs()
    }
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let song = mainViewModel.songs[index]
            mainViewModel.deleteSong(song)
        }
        mainViewModel.fetchSongs()
    }
    func performAction(for song: Song) {
        selectedSong = song
        showDeleteSheet.toggle()
    }
    
#if !os(iOS)
    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
#endif
    
    init() {
        self.mainViewModel.fetchSongs()
    }
    
    var body: some View {
#if os(iOS)
        content
            .navigationBarHidden(true)
#else
        NavigationView {
            content
            Text("Choose a song")
                .foregroundColor(.gray)
        }
#endif
    }
    var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: "My Songs", navType: .DetailView, folder: nil, showBackButton: true, isEditing: $isEditing)
                CustomSearchBar(text: $text, imageName: "magnifyingglass", placeholder: "Search")
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 12)
            Divider()
            ScrollView {
                VStack(spacing: 22) {
                    if mainViewModel.isLoadingSongs {
                        LoadingView()
                    } else {
                        VStack {
                            HStack {
                                ListHeaderView(title: "Pinned")
                                Spacer()
                            }
                            ForEach(mainViewModel.songs) { song in
                                if song.title == "noSongs" {
                                    Text("No Songs")
                                        .foregroundColor(Color.gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .deleteDisabled(true)
                                        .moveDisabled(true)
                                } else {
                                    if song.pinned ?? false {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    if isEditing {
                                                        Button {
                                                            showDeleteSheet = true
                                                            selectedSong = song
                                                        } label: {
                                                            ListIconButtonView(imageName: "trash", color: .red)
                                                        }
                                                        .scaleEffect(isEditing ? 1.0 : 0.7)
                                                    }
                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: nil)) {
                                                        ListRowView(isEditing: $isEditing, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "pin" : "", icon: nil, subtitleForSong: song)
                                                            .contextMenu {
                                                                contextMenu(song: song, showUnpinPinButton: song.pinned ?? false)
                                                            }
                                                            .swipeActions(edge: .leading) {
                                                                Button(action: {
                                                                    if song.pinned ?? false {
                                                                        songViewModel.unpinSong(song)
                                                                        mainViewModel.fetchSongs()
                                                                    } else {
                                                                        songViewModel.pinSong(song)
                                                                        mainViewModel.fetchSongs()
                                                                    }
                                                                }, label: {
                                                                    if song.pinned ?? false {
                                                                        Label("Unpin", systemImage: "pin.slash")
                                                                    } else {
                                                                        Label("Pin", systemImage: "pin")
                                                                    }
                                                                })
                                                                .tint(.yellow)
                                                            }
                                                            .swipeActions(edge: .trailing) {
                                                                swipeActions(song: song)
                                                            }
                                                    }
                                                    if authViewModel.currentUser?.showDataUnderSong ?? "None" == "Show Date" {
                                                        Text(song.timestamp.formatted())
                                                            .foregroundColor(.gray)
                                                    } else if authViewModel.currentUser?.showDataUnderSong ?? "None" == "Show Lyrics" {
                                                        if song.lyrics == "" {
                                                            Text("No lyrics")
                                                                .lineLimit(1)
                                                                .foregroundColor(.gray)
                                                        } else {
                                                            Text(song.lyrics)
                                                                .lineLimit(1)
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: { indexSet in
                                let deletedSongs = indexSet.map { mainViewModel.songs[$0] }
                                for song in deletedSongs {
                                    performAction(for: song)
                                }
                            })
                        }
                        VStack {
                            HStack {
                                ListHeaderView(title: "Songs")
                                Spacer()
                            }
                            ForEach(mainViewModel.songs) { song in
                                if song.title == "noSongs" {
                                    Text("No Songs")
                                        .foregroundColor(Color.gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .deleteDisabled(true)
                                        .moveDisabled(true)
                                } else {
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                if isEditing {
                                                    Button {
                                                        showDeleteSheet = true
                                                        selectedSong = song
                                                    } label: {
                                                        ListIconButtonView(imageName: "trash", color: .red)
                                                    }
                                                }
                                                NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.songs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: nil)) {
                                                    ListRowView(isEditing: $isEditing, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "pin.fill" : "", icon: nil, subtitleForSong: song)
                                                        .contextMenu {
                                                            contextMenu(song: song, showUnpinPinButton: song.pinned ?? false)
                                                        }
                                                        .swipeActions(edge: .leading) {
                                                            Button(action: {
                                                                if song.pinned ?? false {
                                                                    songViewModel.unpinSong(song)
                                                                    mainViewModel.fetchSongs()
                                                                } else {
                                                                    songViewModel.pinSong(song)
                                                                    mainViewModel.fetchSongs()
                                                                }
                                                            }, label: {
                                                                if song.pinned ?? false {
                                                                    Label("Unpin", systemImage: "pin.slash")
                                                                } else {
                                                                    Label("Pin", systemImage: "pin")
                                                                }
                                                            })
                                                            .tint(.yellow)
                                                        }
                                                        .swipeActions(edge: .trailing) {
                                                            swipeActions(song: song)
                                                        }
                                                }
                                            }
                                            if authViewModel.currentUser?.showDataUnderSong ?? "None" == "Show Date" {
                                                Text(song.timestamp.formatted())
                                                    .foregroundColor(.gray)
                                            } else if authViewModel.currentUser?.showDataUnderSong ?? "None" == "Show Lyrics" {
                                                if song.lyrics == "" {
                                                    Text("No lyrics")
                                                        .lineLimit(1)
                                                        .foregroundColor(.gray)
                                                } else {
                                                    Text(song.lyrics)
                                                        .lineLimit(1)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onMove { source, destination in
                                move(from: source, to: destination, folderSongs: mainViewModel.songs)
                            }
                            .onDelete(perform: { indexSet in
                                let deletedSongs = indexSet.map { mainViewModel.songs[$0] }
                                for song in deletedSongs {
                                    performAction(for: song)
                                }
                            })
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .sheet(isPresented: $showMoveSheet) {
                    if let selectedSong = selectedSong {
                        AllSongMoveView(song: selectedSong, showProfileView: $showMoveSheet, songTitle: selectedSong.title)
                    }
                }
                .sheet(isPresented: $showEditSheet, onDismiss: mainViewModel.fetchSongs) {
                    if let selectedSong = selectedSong {
                        SongEditView(song: selectedSong, showProfileView: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? "Not Set"), artist: .constant(selectedSong.artist ?? ""), duration: .constant(selectedSong.duration ?? ""))
                    }
                }
                .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
                    if let selectedSong = selectedSong {
                        Button("Delete", role: .destructive) {
                            print("Deleting song: \(selectedSong.title)")
                            songViewModel.moveSongToRecentlyDeleted(selectedSong)
                            mainViewModel.fetchSongs()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                } message: {
                    if let selectedSong = selectedSong {
                        Text("Are you sure you want to delete \"\(selectedSong.title)\"?")
                    }
                }
            }
        }
    }
    
    func contextMenu(song: Song, showUnpinPinButton: Bool) -> some View {
        return VStack {
            Button {
                selectedSong = song
                songViewModel.fetchSong(selectedSong?.id ?? "") { song in
                    selectedSong = song
                }
                showEditSheet.toggle()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                selectedSong = song
                showMoveSheet.toggle()
            } label: {
                Label("Move", systemImage: "folder")
            }
            Menu {
                Button {
                    selectedSong = song
#if os(iOS)
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.title
#else
                    copyToClipboard(text: selectedSong?.title ?? "")
#endif
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    selectedSong = song
#if os(iOS)
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.lyrics
#else
                    copyToClipboard(text: selectedSong?.lyrics ?? "")
#endif
                } label: {
                    Label("Copy Lyrics", systemImage: "doc.plaintext")
                }
            } label: {
                Label("Copy", systemImage: "doc")
            }
            Button {
                DispatchQueue.main.async {
                    if showUnpinPinButton {
                        songViewModel.unpinSong(song)
                    } else {
                        songViewModel.pinSong(song)
                    }
                    mainViewModel.fetchSongs()
                }
            } label: {
                if showUnpinPinButton {
                    Label("Unpin", systemImage: "pin.slash")
                } else {
                    Label("Pin", systemImage: "pin")
                }
            }
            
            Button(role: .destructive) {
                performAction(for: song)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func swipeActions(song: Song) -> some View {
        return VStack {
            Button {
                performAction(for: song)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button(action: {
                selectedSong = song
                showMoveSheet.toggle()
            }, label: {
                Label("Move", systemImage: "folder")
            })
            .tint(.purple)
            
            Button(action: {
                selectedSong = song
                showEditSheet.toggle()
            }, label: {
                Label("Edit", systemImage: "pencil")
            })
            .tint(.blue)
        }
    }
}
