//
//  SongExploreDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/27/24.
//

import SwiftUI
import BottomSheet
import TipKit

struct SongExploreDetailView: View {
    @ObservedObject var musixmatchService = MusixmatchService.shared
    @ObservedObject var songViewModel = SongViewModel.shared
    
    @State var hasScrolledPastTitle = false
    @State var songWasAdded = false
    @State var showAddedAlert = false
    @State var showErrorAlert = false
    @State var isLoading = false
    
    @State var errorMessage = ""
    
    @State private var offset: CGFloat = 0
    
    let track: Track
    var genres: [MusicGenre] {
        var genres = [MusicGenre]()
        
        for genreListItem in track.primaryGenres.musicGenreList {
            genres.append(genreListItem.musicGenre)
        }
        
        return genres
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CustomNavBar(title: track.trackName, collapsed: .constant(true), collapsedTitle: $hasScrolledPastTitle)
                Spacer()
                Button {
                    self.isLoading = true
                    
                    if let lyrics = musixmatchService.lyrics {
                        songViewModel.createSong(lyrics: lyrics.lyrics_body, title: track.trackName, artist: songViewModel.removeFeatAndAfter(from: track.artistName), key: "") { success, errorMessage in
                            if success {
                                self.showAddedAlert = true
                            } else {
                                self.errorMessage = errorMessage
                                self.showErrorAlert = true
                            }
                        }
                    } else {
                        self.errorMessage = NSLocalizedString("unknown_error_adding_songs", comment: "")
                        self.showErrorAlert = true
                    }
                    
                    self.isLoading = false
                } label: {
                    Image(systemName: songWasAdded ? "checkmark" : "plus")
                        .padding(14)
                        .foregroundColor(isLoading ? .clear : .primary)
                        .font(.body.weight(.semibold))
                        .background(Material.regular)
                        .clipShape(Circle())
                        .overlay {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .showExploreDetailTip()
                }
            }
            .padding()
            .alert(isPresented: .constant(showAddedAlert || showErrorAlert)) {
                if showAddedAlert {
                    return Alert(
                        title: Text("Success!"),
                        message: Text("song_successfully_add_to_library"),
                        dismissButton: .cancel(Text("OK")) {
                            showAddedAlert = false
                        }
                    )
                } else {
                    return Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .cancel(Text("Cancel")) {
                            showErrorAlert = false
                        }
                    )
                }
            }
            Divider()
            if let lyrics = musixmatchService.lyrics {
                ScrollView {
                    VStack(alignment: .leading) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 6) {
                                if !genres.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(genres, id: \.musicGenreId) { genre in
                                                Text(genre.musicGenreName)
                                                    .font(.system(size: 15))
                                                    .padding(8)
                                                    .padding(.horizontal, 4)
                                                    .background(Material.thin)
                                                    .foregroundColor(musixmatchService.getColorFromGenre(genre.musicGenreName))
                                                    .clipShape(Capsule())
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.horizontal, -16)
                                }
                                Text(track.trackName)
                                    .font(.largeTitle.weight(.bold))
                                Text(track.artistName)
                                    .foregroundColor(.gray)
                            }
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(lyrics.lyrics_body)
                        }
                    }
                    .padding()
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        DispatchQueue.main.async {
                            self.offset = value.first ?? 0
                            
                            withAnimation(.easeInOut(duration: 0.22)) {
                                if offset <= 75 {
                                    hasScrolledPastTitle = true
                                } else {
                                    hasScrolledPastTitle = false
                                }
                            }
                        }
                    }
                }
            } else {
                ProgressView("Loading")
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            musixmatchService.fetchLyrics(forTrackId: track.trackId)
        }
    }
}
