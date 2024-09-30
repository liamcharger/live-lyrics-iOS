//
//  AddSongsView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/11/23.
//

import SwiftUI

struct AddSongsView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @Environment(\.presentationMode) var presMode
    
    @State private var errorMessage = ""
    @State private var searchText = ""
    
    @State private var showError = false
    @State private var showSearchBar = false
    @State private var isLoading = false
    
    @State private var selectedSongs: [Song] = []
    
    let folder: Folder
    
    var searchableSongs: [Song] {
        let songs = (mainViewModel.sharedSongs + mainViewModel.songs).sorted(by: { song1, song2 in
            return song1.title.lowercased() < song2.title.lowercased()
        })
        
        if searchText.isEmpty {
            return songs
        } else {
            let lowercasedQuery = searchText.lowercased()
            return songs.filter({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    func addToFolder() {
        for song in mainViewModel.folderSongs {
            if !selectedSongs.contains(where: { $0.id == song.id }) {
                mainViewModel.deleteSong(folder, song)
            }
        }
        
        var songs: [Song] = []
        let dispatch = DispatchGroup()
        
        for song in selectedSongs {
            dispatch.enter()
            songViewModel.fetchSong(listen: false, song.id!) { song in
                if let song = song {
                    songs.append(song)
                }
                dispatch.leave()
            } regCompletion: { _ in }
        }
        
        dispatch.notify(queue: .main) {
            songViewModel.moveSongsToFolder(folder: folder, songs: songs) { error in
                if let error = error {
                    if error.localizedDescription == "Failed to get document because the client is offline." {
                        self.errorMessage = "Please connect to the internet to perform this action."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showError = true
                } else {
                    presMode.wrappedValue.dismiss()
                }
                self.isLoading = false
            }
        }
    }
    
    func checkForSongs() {
        let songIdsSet = Set(mainViewModel.songs.map { $0.id })
        
        selectedSongs = mainViewModel.folderSongs.filter { song in
            songIdsSet.contains(song.id)
        }
        
        let sharedSongs = mainViewModel.sharedSongs.filter { song in
            mainViewModel.folderSongs.contains { $0.id == song.id }
        }
        selectedSongs += sharedSongs
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Add Songs")
                    .font(.title.weight(.bold))
                Spacer()
                if !showSearchBar {
                    Button(action: {
                        withAnimation(.bouncy(extraBounce: 0.1)) {
                            showSearchBar.toggle()
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .background(Material.regular)
                            .clipShape(Capsule())
                    }
                }
                SheetCloseButton {
                    presMode.wrappedValue.dismiss()
                }
                if !selectedSongs.isEmpty {
                    Button(action: {
                        isLoading = true
                        addToFolder()
                    }) {
                        Image(systemName: "checkmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(isLoading ? .clear : .white)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .opacity(isLoading ? 0.5 : 1.0)
                    .disabled(isLoading)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.primary)
                        }
                    }
                }
            }
            .padding()
            Divider()
            if mainViewModel.isLoadingSongs || mainViewModel.isLoadingFolderSongs || mainViewModel.isLoadingSharedSongs {
                VStack {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                }
            } else {
                ScrollView {
                    if showSearchBar {
                        HStack(spacing: 6) {
                            CustomSearchBar(text: $searchText, imageName: "magnifyingglass", placeholder: NSLocalizedString("search", comment: ""))
                            SheetCloseButton {
                                withAnimation(.bouncy(extraBounce: 0.1)) {
                                    searchText = ""
                                    showSearchBar.toggle()
                                }
                            }
                        }
                        .padding([.horizontal, .top])
                    }
                    VStack(alignment: .leading) {
                        if searchableSongs.isEmpty {
                            Text("No Songs")
                                .foregroundColor(Color.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        ForEach(searchableSongs) { song in
                            Button(action: {
                                if selectedSongs.contains(where: { $0.id == song.id }) {
                                    selectedSongs.removeAll(where: { $0.id == song.id })
                                } else {
                                    selectedSongs.append(song)
                                }
                            }) {
                                HStack(spacing: 7) {
                                    Text(song.title)
                                        .lineLimit(1)
                                    if song.uid != AuthViewModel.shared.currentUser?.id {
                                        Image(systemName: "person.2")
                                            .font(.system(size: 16).weight(.medium))
                                    }
                                    Spacer()
                                    if selectedSongs.contains(where: { $0.id == song.id }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .imageScale(.large)
                                    } else {
                                        Image(systemName: "circle")
                                            .imageScale(.large)
                                    }
                                }
                                .padding()
                                .background(Material.regular)
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                                .contextMenu {
                                    Button(action: {
                                        if selectedSongs.contains(where: { $0.id == song.id }) {
                                            selectedSongs.removeAll(where: { $0.id == song.id })
                                        } else {
                                            selectedSongs.append(song)
                                        }
                                    }) {
                                        if selectedSongs.contains(where: { $0.id == song.id }) {
                                            Label("Deselect", systemImage: "circle")
                                        } else {
                                            Label("Select", systemImage: "checkmark.circle.fill")
                                        }
                                    }
                                }
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if mainViewModel.isLoadingSharedSongs {
                mainViewModel.fetchSharedSongs {
                    checkForSongs()
                }
            } else {
                checkForSongs()
            }
        }
        .onChange(of: mainViewModel.folderSongs) { _ in
            checkForSongs()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Can't save song to \"\(folder.title)\""), message: Text(errorMessage), dismissButton: .cancel(Text("Cancel"), action: {}))
        }
    }
}
