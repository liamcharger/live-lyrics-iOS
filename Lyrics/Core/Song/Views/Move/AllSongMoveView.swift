//
//  SongMoveView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
import FASwiftUI
#endif

struct AllSongMoveView: View {
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    @Binding var showProfileView: Bool
    
    let song: Song
    let songTitle: String
    
    @State var errorMessage = ""
    @State var text = ""
    
    @State var showError = false
    @State var showNewFolderView = false
    
    @FocusState var isFocused: Bool
    
    init(song: Song, showProfileView: Binding<Bool>, songTitle: String) {
        self.song = song
        self.songTitle = songTitle
        self._showProfileView = showProfileView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Navbar
            HStack(alignment: .center, spacing: 10) {
                // MARK: User info
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
                SheetCloseButton(isPresented: $showProfileView)
            }
            .padding([.leading, .top, .trailing])
            .padding(.bottom, 8)
            .padding(8)
            Divider()
            if mainViewModel.folders.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        LoadingView()
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(mainViewModel.folders) { folder in
                            if folder.title == "noFolders" {
                                Text("No Folders")
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                Button(action: {songViewModel.moveSongToFolder(toFolder: folder, song) { success in
                                    if success {
                                        showProfileView = false
                                    } else {
                                        showError = true
                                    }
                                } completionString: { errorMessage in
                                    if errorMessage == "Failed to get document because the client is offline." {
                                        self.errorMessage = "Please connect to the internet to perform this action."
                                    } else {
                                        self.errorMessage = errorMessage
                                    }
                                }
                                }, label: {
                                    HStack {
                                        FAText(iconName: "folder-closed", size: 18)
                                        Text(folder.title)
                                            .lineLimit(1)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Material.regular)
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                })
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Failed to move song"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
