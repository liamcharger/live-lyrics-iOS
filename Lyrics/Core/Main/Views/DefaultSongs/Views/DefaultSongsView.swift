//
//  DefaultSongsView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/1/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif

struct DefaultSongsView: View {
    // Object vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var songDetailViewModel = SongDetailViewModel()
    @ObservedObject var networkManager = NetworkManager()
    @EnvironmentObject var viewModel: AuthViewModel
    
    // State vars
    @State var searchText = ""
    @State var artist = ""
    @State var errorMessage = ""
    @State var trackName = ""
    
    @State var song: Track?
    @State var albumInfo: AlbumDetailsResponse?
    @State var id: Int?
    
    @State var showDetailViewNavLink = false
    @State var showSearchSheet = false
    @State var showAlert = false
    @State var showExplicitAlert = false
    @State var showError = false
    @State var isLoading: Bool? = false
    
    var songsArray = [Song]()
    
    func saveSongToMySongs(song: Track) {
        songViewModel.addSongToMySongs(id: UUID().uuidString, lyrics: "Lyrics here...", title: song.track_name, artist: song.artist_name, timestamp: Date.now, key: "", bpm: "BPM") { success, errorMessage in
            if success {
                self.showAlert = true
                self.mainViewModel.fetchSongs()
            } else {
                self.errorMessage = errorMessage
                self.showError = true
            }
        }
    }
    
    func fetchSongData(song: Track) {
        songDetailViewModel.fetchLyrics(trackId: song.track_id) { success, errorMessage in
            if success {
                songDetailViewModel.fetchAlbumDetails(albumId: song.album_id) { result in
                    switch result {
                    case .success(let albumInfo):
                        self.showDetailViewNavLink = true
                        self.isLoading = false
                        self.albumInfo = albumInfo
                    case .failure(let error):
                        print("Error fetching album info: \(error)")
                    }
                }
            }
            else {
                print("Error fetching lyrics")
                self.isLoading = false
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
    }
    
    var body: some View {
        if networkManager.isConnected {
            if viewModel.currentUser?.hasSubscription ?? false {
                content
            } else {
//                ZStack {
                    content
//                        .blur(radius: 25)
//                        .disabled(true)
//                    VStack(spacing: 35) {
//                        VStack(spacing: 8) {
//                            Text("You've run into a Premium feature!")
//                                .multilineTextAlignment(.center)
//                                .font(.title.weight(.bold))
//                            Text("Subscribe to access it.")
//                        }
//                        VStack {
//                            Button {
//                                
//                            } label: {
//                                Text("Subscribe")
//                                    .modifier(NavButtonViewModifier())
//                                    .padding(.horizontal)
//                            }
//                        }
//                    }
//                }
            }
        } else {
            ZStack {
                VStack {
                    VStack(spacing: 10) {
                        CustomNavBar(title: "Top Songs", navType: .DefaultSongs, folder: nil, showBackButton: true, isEditing: $networkManager.isConnected)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    content
                        .blur(radius: 25)
                        .disabled(true)
                }
                NoInternetView()
            }
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                CustomNavBar(title: "Top Songs", navType: .DefaultSongs, folder: nil, showBackButton: true, isEditing: $networkManager.isConnected)
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 12)
            if songDetailViewModel.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                Divider()
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(songDetailViewModel.tracks, id: \.track_id) { song in
                            if song.explicit == 1 && !(viewModel.currentUser?.showsExplicitSongs ?? true) {
                                Button {
                                    self.showExplicitAlert.toggle()
                                } label: {
                                    RowView(
                                        title: song.track_name,
                                        subtitle: song.artist_name,
                                        trackId: song.track_id,
                                        id: id,
                                        isExplicit: song.explicit,
                                        isLoading: $isLoading
                                    )
                                }
                            } else {
                                NavigationLink(isActive: $showDetailViewNavLink) {
                                    SongDetailView(song: Song(id: String(song.track_id), uid: viewModel.currentUser?.id ?? "", timestamp: Date.now, title: trackName, lyrics: songDetailViewModel.lyrics, artist: song.artist_name, songId: song.track_id), songs: nil, restoreSong: nil, wordCountStyle: viewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: true, albumData: albumInfo, folder: nil)
                                } label: {
                                    Button {
                                        self.id = song.track_id
                                        self.trackName = song.track_name
                                        self.isLoading = true
                                        self.fetchSongData(song: song)
                                    } label: {
                                        RowView(title: song.track_name, subtitle: song.artist_name, trackId: song.track_id, id: id, isExplicit: song.explicit, isLoading: $isLoading)
                                    }
                                    .alert(isPresented: $showError) {
                                        Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showExplicitAlert) {
            Alert(title: Text("It looks like this song is explicit"), message: Text("You have turned explicit songs off."), dismissButton: .cancel())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}
