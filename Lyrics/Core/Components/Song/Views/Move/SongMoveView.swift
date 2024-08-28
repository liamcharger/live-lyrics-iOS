//
//  SongMoveView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI

struct SongMoveView: View {
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @Binding var showProfileView: Bool
    
    let song: Song
    let songTitle: String
    
    @State var selectedFolders: [Folder] = []
    
    @State var errorMessage = ""
    
    @State var isLoading = false
    @State var showError = false
    @State var showNewFolderView = false
    
    func move() {
        let dispatch = DispatchGroup()
        
        for folder in selectedFolders {
            dispatch.enter()
            songViewModel.moveSongsToFolder(folder: folder, songs: [song]) { error in
                dispatch.leave()
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
        
        // Show "song already in folder" alert?
        dispatch.notify(queue: .main) {
            self.isLoading = false
            self.showProfileView = false
        }
    }
    
    init(song: Song, showProfileView: Binding<Bool>, songTitle: String) {
        self.song = song
        self.songTitle = songTitle
        self._showProfileView = showProfileView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Move \"\(songTitle)\"")
                    .font(.system(size: 28, design: .rounded).weight(.bold))
                Spacer()
                Button(action: {showNewFolderView = true}) {
                    Image(systemName: "plus")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Material.regular)
                        .clipShape(Circle())
                }
                .sheet(isPresented: $showNewFolderView) {
                    NewFolderView(isDisplayed: $showNewFolderView)
                }
                SheetCloseButton {
                    showProfileView = false
                }
                if !selectedFolders.isEmpty {
                    Button(action: {
                        isLoading = true
                        move()
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
            ScrollView {
                if mainViewModel.folders.isEmpty {
                    LoadingView()
                } else {
                    VStack(alignment: .leading) {
                        ForEach(mainViewModel.folders) { folder in
                            if folder.title == "noFolders" {
                                Text("No Folders")
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                Button(action: {
                                    if selectedFolders.contains(where: { $0.id == folder.id }) {
                                        selectedFolders.removeAll(where: { $0.id == folder.id })
                                    } else {
                                        selectedFolders.append(folder)
                                    }
                                }, label: {
                                    HStack {
                                        FAText(iconName: "folder-closed", size: 18)
                                        Text(folder.title)
                                            .lineLimit(1)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        if selectedFolders.contains(where: { $0.id == folder.id }) {
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
                                })
                                .disabled(isLoading)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
