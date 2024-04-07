//
//  AddSongsView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/11/23.
//

import SwiftUI

struct AddSongsView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    @State var errorMessage = ""
    @State var searchText = ""
    
    @State var showError = false
    @State var showSearchAlert = false
    @State var isLoading = false
    @State var songAlreadyInFolder = false
    
    @State var selectedSongs: [String: Bool] = [:]
    
    let folder: Folder
    var songs: [Song]
    
    var searchableSongs: [Song] {
        if searchText.isEmpty {
            return mainViewModel.songs
        } else {
            if !showSearchAlert {
                let lowercasedQuery = searchText.lowercased()
                return mainViewModel.songs.filter ({
                    $0.title.lowercased().contains(lowercasedQuery)
                })
            } else {
                return mainViewModel.songs
            }
        }
    }
    
    func addToFolder() {
        var songs: [Song] = []
        
        let dispatchGroup = DispatchGroup()
        
        for(songID, isSelected) in selectedSongs {
            guard isSelected else {
                continue
            }
            
            dispatchGroup.enter()
            
            self.songViewModel.fetchSong(songID) { song in
                songs.append(song)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.songViewModel.moveSongsToFolder(folder: folder, songs: songs) { success, errorMessage in
                if success {
                    presMode.wrappedValue.dismiss()
                    self.isLoading = false
                } else {
                    if errorMessage == "Failed to get document because the client is offline." {
                        self.errorMessage = "Please connect to the internet to perform this action."
                        self.showError = true
                        self.isLoading = false
                    } else if errorMessage.contains("is already in the specified folder") {
                        self.songAlreadyInFolder = true
                        self.isLoading = false
                    } else {
                        self.errorMessage = errorMessage
                        self.showError = true
                        self.isLoading = false
                    }
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
                    print(song.title)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                Text("Add Songs")
                    .font(.title.weight(.bold))
                Spacer()
                Button(action: {showSearchAlert.toggle()}) {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Capsule())
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
                        if isLoading {
                            ProgressView()
                                .padding(12)
                                .background(Material.regular)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "checkmark")
                                .imageScale(.medium)
                                .padding(12)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .background {
                                    Rectangle()
                                        .fill(.clear)
                                        .background(Material.regular)
                                        .mask { Circle()
                                            
                                        }
                                }
                        }
                    }
                }
            }
            .padding()
            Spacer()
            if mainViewModel.isLoadingSongs {
                VStack {
                    ScrollView {
                        LoadingView()
                    }
                }
                .padding()
            } else {
                ScrollView {
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
                                            selectedSongs[songID] = nil // Deselect
                                        } else {
                                            selectedSongs[songID] = true // Select
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
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            mainViewModel.fetchSongs()
            checkForSongs()
        }
        .alert("Enter the name of the song you're looking for.", isPresented: $showSearchAlert) {
            TextField("Search...", text: $searchText)
            Button("Cancel", role: .cancel) { }
            Button("Search", action: {})
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Can't save song to \"\(folder.title)\""), message: Text(errorMessage), dismissButton: .cancel(Text("Cancel"), action: {}))
        }
        .alert(isPresented: $songAlreadyInFolder) {
            Alert(title: Text("One or more songs were not added because they were already in \"\(folder.title)\""), dismissButton: .cancel(Text("OK"), action: {presMode.wrappedValue.dismiss()}))
        }
    }
}
