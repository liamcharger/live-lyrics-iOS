//
//  DefaultSongSearchView.swift
//  Lyrics
//
//  Created by Liam Willey on 8/14/23.
//

import SwiftUI
#if os(iOS)
import BottomSheet
#endif

struct DefaultSongSearchView: View {
    // Object vars
    @ObservedObject var mainViewModel = MainViewModel()
    @ObservedObject var songViewModel = SongViewModel()
    @ObservedObject var songDetailViewModel = SongDetailViewModel()
    @ObservedObject var networkManager = NetworkManager()
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presMode
    
    // State vars
    @State var searchText = ""
    @State var artist = ""
    @State var errorMessage = ""
    @State var trackName = ""
    
    @State var song: Track?
    @State var albumInfo: AlbumDetailsResponse?
    @State var id: Int?
    
    @State var showSongRepititionAlert = false
    @State var isLoading: Bool? = false
    @State var showInfo = false
    @State var showResults = false
    @State var showResults2 = false
    @State var showAlert = false
    @State var showExplicitAlert = false
    @State var showError = false
    
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
    func fetchSongData(song: SearchTrack) {
        songDetailViewModel.fetchLyrics(trackId: song.track.track_id) { success, errorMessage in
            if success {
                songDetailViewModel.fetchAlbumDetails(albumId: song.track.album_id) { result in
                    switch result {
                    case .success(let albumInfo):
                        self.showResults2 = true
                        self.isLoading = false
                        self.albumInfo = albumInfo
                    case .failure(let error):
                        print("Error fetching album info: \(error)")
                    }
                }
            } else {
                print("Error fetching lyrics")
                self.isLoading = false
                self.showError = true
                self.errorMessage = errorMessage
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if networkManager.isConnected {
                if viewModel.currentUser?.hasSubscription ?? false {
//                    content
                } else {
//                    ZStack {
                        content
//                            .blur(radius: 25)
//                            .disabled(true)
//                        VStack(spacing: 35) {
//                            VStack(spacing: 8) {
//                                Text("You've run into a Premium feature!")
//                                    .multilineTextAlignment(.center)
//                                    .font(.title.weight(.bold))
//                                Text("Subscribe to access it.")
//                            }
//                            VStack {
//                                Button {
//                                    
//                                } label: {
//                                    Text("Subscribe")
//                                        .padding(12)
//                                        .background(.blue)
//                                        .foregroundColor(.white)
//                                        .clipShape(Capsule())
//                                        .padding(.horizontal)
//                                }
//                            }
//                        }
//                    }
                }
            } else {
                ZStack {
                    content
                        .blur(radius: 25)
                        .disabled(true)
                    NoInternetView()
                }
            }
        }
    }
    
    var content: some View {
        VStack {
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    // MARK: User info
                    Text("Enter the name of the song you're looking for.")
                        .font(.title.weight(.bold))
                    Spacer()
                    Button(action: {presMode.wrappedValue.dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .padding(12)
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color("Color"))
                            .background(Material.regular)
                            .clipShape(Circle())
                    }
                }
                .padding(.top)
                .padding(8)
                Spacer()
                CustomTextField(text: $searchText, placeholder: "Song Title")
                CustomTextField(text: $artist, placeholder: "Artist Name")
                Spacer()
                NavigationLink(isActive: $showResults) {
                    if songDetailViewModel.isLoading {
                        LoadingView()
                    } else {
                        if songDetailViewModel.searchResults.isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("No Results")
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                VStack(alignment: .leading) {
                                    ForEach(songDetailViewModel.searchResults, id: \.track.track_id) { result in
                                        if result.track.explicit == 1 && !(viewModel.currentUser?.showsExplicitSongs ?? true) {
                                            Button {
                                                self.showExplicitAlert.toggle()
                                            } label: {
                                                RowView(
                                                    title: result.track.track_name,
                                                    subtitle: result.track.artist_name,
                                                    trackId: result.track.track_id,
                                                    id: id,
                                                    isExplicit: result.track.explicit,
                                                    isLoading: $isLoading
                                                )
                                            }
                                            .padding(.horizontal)
                                        } else {
                                            NavigationLink(isActive: $showResults2) {
                                                SongDetailView(song: Song(id: String(result.track.track_id), uid: viewModel.currentUser?.id ?? "", timestamp: Date.now, title: trackName, lyrics: songDetailViewModel.lyrics, artist: result.track.artist_name, songId: result.track.track_id), songs: nil, restoreSong: nil, wordCountStyle: viewModel.currentUser?.wordCountStyle ?? "Words", isDefaultSong: true, albumData: albumInfo, folder: nil)
                                                    .padding(.top)
                                            } label: {
                                                Button {
                                                    self.id = result.track.track_id
                                                    self.trackName = result.track.track_name
                                                    self.isLoading = true
                                                    self.fetchSongData(song: result)
                                                } label: {
                                                    RowView(title: result.track.track_name, subtitle: result.track.artist_name, trackId: result.track.track_id, id: id, isExplicit: result.track.explicit, isLoading: $isLoading)
                                                }
                                                .padding(.horizontal)
                                                .alert(isPresented: $showError) {
                                                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .navigationTitle("Search Results")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                } label: {
                    Button(action: {
                        songDetailViewModel.searchSongs(trackName: searchText, artist: artist)
                        showResults = true
                    }, label: {
                        Text("Search")
                            .frame(maxWidth: .infinity)
                            .modifier(NavButtonViewModifier())
                    })
                    .opacity(searchText.trimmingCharacters(in: .whitespaces).isEmpty || artist.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    .padding(.bottom)
                }
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty || artist.trimmingCharacters(in: .whitespaces).isEmpty)
                
                HStack {
                    Spacer()
                    Text("Powered by Musixmatch")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .padding(.top, -16)
                        .padding(.bottom)
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(NSLocalizedString("error", comment: "Error")), message: Text(errorMessage), dismissButton: .cancel())
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text("The song was successfully added to your library."), dismissButton: .cancel())
        }
        .alert(isPresented: $showExplicitAlert) {
            Alert(title: Text("It looks like this song is explicit"), message: Text("You have turned explicit songs off."), dismissButton: .cancel())
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}
