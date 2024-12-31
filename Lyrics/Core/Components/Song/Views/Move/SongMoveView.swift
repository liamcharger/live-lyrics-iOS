//
//  SongMoveView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI

struct SongMoveView: View {
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var mainViewModel = MainViewModel.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    let song: Song
    
    @State var selectedFolders: [Folder] = []
    
    @State var errorMessage = ""
    
    @State var isLoading = false
    @State var showError = false
    @State var showNewFolderView = false
    
    var folders: [Folder] {
        return mainViewModel.sharedFolders + mainViewModel.folders
    }
    
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
            self.presMode.wrappedValue.dismiss()
        }
    }
    
    init(song: Song) {
        self.song = song
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("Move \(song.title)")
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
                CloseButton {
                    presMode.wrappedValue.dismiss()
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
            if mainViewModel.isLoadingSharedFolders || mainViewModel.isLoadingFolders || folders.isEmpty {
                FullscreenMessage(imageName: "circle.slash", title: "you_dont_have_any_folders", spaceNavbar: true, isLoading: (mainViewModel.isLoadingSharedFolders || mainViewModel.isLoadingFolders))
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(folders) { folder in
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
                                        HStack(spacing: 7) {
                                            Text(folder.title)
                                                .lineLimit(1)
                                                .multilineTextAlignment(.leading)
                                            if folder.uid ?? "" != uid() {
                                                Image(systemName: "person.2")
                                                    .font(.system(size: 16).weight(.medium))
                                            }
                                        }
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
