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
    
    @State var errorMessage = ""
    @State var searchText = ""
    
    @State var showError = false
    @State var showSearchBar = false
    @State var isLoading = false
    
    @State var selectedSongs: [String: Bool] = [:]
    
    let folder: Folder
    
    var searchableSongs: [Song] {
        if searchText.isEmpty {
            return mainViewModel.songs
        } else {
            let lowercasedQuery = searchText.lowercased()
            return mainViewModel.songs.filter ({
                $0.title.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    func addToFolder() {
        for song in mainViewModel.folderSongs {
            if let songID = song.id, selectedSongs[songID] == nil {
                mainViewModel.deleteSong(folder, song)
            }
        }
        
        var songs: [Song] = []
        let dispatch = DispatchGroup()
        
        for(songID, isSelected) in selectedSongs {
            guard isSelected else {
                continue
            }
            
            dispatch.enter()
            self.songViewModel.fetchSong(listen: false, songID) { song in
                if let song = song {
                    songs.append(song)
                }
                dispatch.leave()
            } regCompletion: { _ in }
        }
        
        dispatch.notify(queue: .main) {
            self.songViewModel.moveSongsToFolder(folder: folder, songs: songs) { error in
                if let error = error {
                    if error.localizedDescription == "Failed to get document because the client is offline." {
                        self.errorMessage = "Please connect to the internet to perform this action."
                        self.showError = true
                        self.isLoading = false
                    } else {
                        self.errorMessage = errorMessage
                        self.showError = true
                        self.isLoading = false
                    }
                } else {
                    presMode.wrappedValue.dismiss()
                    self.isLoading = false
                }
            }
        }
    }
    
    func checkForSongs() {
        for song in mainViewModel.folderSongs {
            if let songID = song.id {
                let isSongInMainSongs = mainViewModel.songs.contains(where: { $0.id == songID })
                if isSongInMainSongs {
                    selectedSongs[songID] = true
                }
            }
        }
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
                Button(action: {presMode.wrappedValue.dismiss()}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Capsule())
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
                                .opacity(1)
                                .tint(.primary)
                        }
                    }
                }
            }
            .padding()
            Divider()
            if mainViewModel.isLoadingSongs || mainViewModel.isLoadingFolderSongs {
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
                            Button(action: {
                                withAnimation(.bouncy(extraBounce: 0.1)) {
                                    searchText = ""
                                    showSearchBar.toggle()
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .imageScale(.medium)
                                    .padding(12)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .background(Material.regular)
                                    .clipShape(Capsule())
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
                            if song.title == "noSongs" {
                                Text("No Songs")
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                Button(action: {
                                    if let songID = song.id {
                                        if selectedSongs[songID] != nil {
                                            selectedSongs[songID] = nil
                                        } else {
                                            selectedSongs[songID] = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text(song.title)
                                            .lineLimit(1)
                                        Spacer()
                                        if let songID = song.id {
                                            if let isSelected = selectedSongs[songID] {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .imageScale(.large)
                                            } else {
                                                Image(systemName: "circle")
                                                    .imageScale(.large)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                    .contextMenu {
                                        Button(action: {
                                            if let songID = song.id {
                                                if selectedSongs[songID] != nil {
                                                    selectedSongs[songID] = nil // Deselect
                                                } else {
                                                    selectedSongs[songID] = true // Select
                                                }
                                            }
                                        }) {
                                            if let songID = song.id {
                                                if selectedSongs[songID] != nil {
                                                    Label("Deselect", systemImage: "circle")
                                                } else {
                                                    Label("Select", systemImage: "checkmark.circle.fill")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            checkForSongs()
        }
        .onChange(of: mainViewModel.folderSongs) { _ in
            checkForSongs()
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Can't save song to \"\(folder.title)\""), message: Text(errorMessage), dismissButton: .cancel(Text("Cancel"), action: {}))
        }
    }
}
