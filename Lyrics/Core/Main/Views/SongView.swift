//
//  SongView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/10/23.
//

import SwiftUI
#if os(iOS)
import MobileCoreServices
#endif

struct SongView: View {
    // Object vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var networkManager = NetworkManager()
    @StateObject var authViewModel = AuthViewModel()
    
    // State vars
    @State var text = ""
    @State var title = ""
    @State var isChecked = ""
    
    @State var showMenu = false
    @State var showAddSongsView = false
    @State var showNewSong = false
    @State var showMoveSheet = false
    @State var showDeleteSheet = false
    @State var showEditSheet = false
    @State var showFolderEditSheet = false
    @State var showChooseSongSheet = false
    @State var showExistingSongChooseSheet = false
    @State var isEditing = false
    @State var isShowingUnpinPin = false
    
    @State private var selectedSong: Song?
    
    // Let vars
    let folder: Folder
    
    // Standard vars
//    var mainViewModel.folderSongs: [Song] {
//        if text.isEmpty {
//            return mainViewModel.folderSongs
//        } else {
//            let lowercasedQuery = text.lowercased()
//            return mainViewModel.folderSongs.filter ({
//                $0.title.lowercased().contains(lowercasedQuery)
//            })
//        }
//    }
#if os(iOS)
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
#endif
    
    func move(from source: IndexSet, to destination: Int) {
        mainViewModel.updateSongOrder(folder: folder)
        mainViewModel.folderSongs.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let song = mainViewModel.folderSongs[index]
            mainViewModel.deleteSong(folder, song)
        }
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
    
    init(folder: Folder) {
        self.folder = folder
        self._title = State(initialValue: folder.title)
    }
    
    var body: some View {
        content
            .navigationBarHidden(true)
            .onAppear {
                mainViewModel.fetchSongs(folder)
            }
            .onDisappear {
                mainViewModel.removeFolderSongEventListener()
            }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: folder.title, navType: .DetailView, folder: folder, showBackButton: true, isEditing: $isEditing)
                CustomSearchBar(text: $text, imageName: "magnifyingglass", placeholder: "Search")
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 12)
            Divider()
            ScrollView {
                VStack(spacing: 22) {
                    if mainViewModel.isLoadingFolderSongs {
                        LoadingView()
                    } else {
                        VStack {
                            Button(action: {showChooseSongSheet.toggle()}) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "square.and.pencil")
                                    Text("Add Songs")
                                    Spacer()
                                }
                                .padding(12)
                                .background(.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            .alert("Create a new song or choose existing songs?", isPresented: $showChooseSongSheet, actions: {
                                Button(action: {showNewSong.toggle()}, label: {Text("Create a New Song")})
                                Button(action: {showAddSongsView.toggle()}, label: {Text("Choose Existing Songs")})
                                Button(role: .cancel, action: {}, label: {Text("Cancel")})
                            })
                            .sheet(isPresented: $showNewSong) {
                                NewSongView(isDisplayed: $showNewSong, folder: folder)
                            }
                            .sheet(isPresented: $showAddSongsView) {
                                AddSongsView(folder: folder, songs: mainViewModel.folderSongs)
                            }
                            Button(action: {showFolderEditSheet.toggle()}) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "pencil")
                                    Text("Edit Folder")
                                    Spacer()
                                }
                                .padding(12)
                                .background(.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            .sheet(isPresented: $showFolderEditSheet) {
                                FolderEditView(folder: folder, showView: $showFolderEditSheet, title: $title)
                            }
                        }
                        VStack {
                            HStack {
                                ListHeaderView(title: "Pinned")
                                Spacer()
                            }
                            ForEach(mainViewModel.folderSongs) { song in
                                if song.title == "noSongs" {
                                    Text("No Songs")
                                        .foregroundColor(Color.gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .deleteDisabled(true)
                                        .moveDisabled(true)
                                } else {
                                    if song.pinned ?? false {
                                        HStack {
                                            if isEditing {
                                                Button {
                                                    showDeleteSheet = true
                                                    selectedSong = song
                                                } label: {
                                                    ListIconButtonView(imageName: "trash", color: .red)
                                                }
                                            }
                                            HStack {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: folder)) {
                                                        ListRowView(isEditing: $isEditing, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "pin" : "", icon: nil, subtitleForSong: song)
                                                            .contextMenu {
                                                                contextMenu(song: song, showUnpinPinButton: song.pinned ?? false)
                                                            }
                                                            .swipeActions(edge: .leading) {
                                                                Button(action: {
                                                                    if song.pinned ?? false {
                                                                        songViewModel.unpinSong(song)
                                                                    } else {
                                                                        songViewModel.pinSong(song)
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
                            }
                            .onDelete(perform: { indexSet in
                                let deletedSongs = indexSet.map { mainViewModel.folderSongs[$0] }
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
                            ForEach(mainViewModel.folderSongs) { song in
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
                                                    .scaleEffect(isEditing ? 1.0 : 0.7)
                                                }
                                                NavigationLink(destination: SongDetailView(song: song, songs: mainViewModel.folderSongs, restoreSong: nil, wordCountStyle: authViewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: false, albumData: nil, folder: folder)) {
                                                    ListRowView(isEditing: $isEditing, title: song.title, navArrow: "chevron.right", imageName: song.pinned ?? false ? "pin.fill" : "", icon: nil, subtitleForSong: song)
                                                        .contextMenu {
                                                            contextMenu(song: song, showUnpinPinButton: song.pinned ?? false)
                                                        }
                                                        .swipeActions(edge: .leading) {
                                                            Button(action: {
                                                                if song.pinned ?? false {
                                                                    songViewModel.unpinSong(song)
                                                                } else {
                                                                    songViewModel.pinSong(song)
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
                                                        .foregroundColor(.clear)
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
                            .onMove(perform: move)
                            .onDelete(perform: { indexSet in
                                let deletedSongs = indexSet.map { mainViewModel.folderSongs[$0] }
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
                .sheet(isPresented: $showEditSheet) {
                    if let selectedSong = selectedSong {
                        SongEditView(song: selectedSong, showProfileView: $showEditSheet, title: .constant(selectedSong.title), key: .constant(selectedSong.key ?? "Not Set"), artist: .constant(selectedSong.artist ?? ""), duration: .constant(selectedSong.duration ?? ""))
                    }
                }
                .confirmationDialog("Delete Song", isPresented: $showDeleteSheet) {
                    if let selectedSong = selectedSong {
                        Button("Delete", role: .destructive) {
                            print("Deleting song: \(selectedSong.title)")
                            songViewModel.moveSongToRecentlyDeleted(folder, selectedSong)
                        }
                        Button("Remove from Folder") {
                            mainViewModel.deleteSong(folder, selectedSong)
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                } message: {
                    if let selectedSong = selectedSong {
                        Text("Are you sure you want to delete \"\(selectedSong.title)\"?")
                    }
                }
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
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.title
                } label: {
                    Label("Copy Title", systemImage: "textformat")
                }
                Button {
                    selectedSong = song
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = selectedSong?.lyrics
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
}
