//
//  SongMoveView.swift
//  Lyrics
//
//  Created by Liam Willey on 5/22/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif

struct AllSongMoveView: View {
    // Environment vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @Environment(\.presentationMode) var presMode
    
    // Binding vars
    @Binding var showProfileView: Bool
    
    // Let vars
    let song: Song
    let songTitle: String
    
    // State vars
    @State var errorMessage = ""
    @State var text = ""
    
    @State var showError = false
    @State var showNewFolderView = false
    
    // FocusState vars
    @FocusState var isFocused: Bool
    
    // Init
    init(song: Song, showProfileView: Binding<Bool>, songTitle: String) {
        self.song = song
        self.songTitle = songTitle
        self._showProfileView = showProfileView
    }
    
    var body: some View {
        VStack {
            // MARK: Navbar
            HStack(alignment: .center, spacing: 10) {
                // MARK: User info
                Text("Move \"\(songTitle)\"")
                    .font(.title.weight(.bold))
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
            .padding(8)
            Spacer()
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
                    VStack(alignment: .leading, spacing: 15) {
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
                                    RowView(title: folder.title, subtitle: nil, trackId: nil, id: nil, isExplicit: nil, isLoading: .constant(false))
                                })
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Failed to move song"), message: Text(errorMessage), dismissButton: .cancel())
        }
    }
}
