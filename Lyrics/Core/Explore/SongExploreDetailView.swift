//
//  SongExploreDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/27/24.
//

import SwiftUI
import BottomSheet

struct SongExploreDetailView: View {
    @ObservedObject var musixmatchService = MusixmatchService.shared
    
    @State var lyrics: Lyrics?
    @State var showDetailSheet = false
    @State var hasScrolledPastTitle = false
    @State var showDivider = false
    
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
                CustomBackButton()
                if hasScrolledPastTitle {
                    Text(track.trackName)
                        .font(.system(size: 28, design: .rounded).weight(.bold))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
                .opacity(showDivider ? 1 : 0)
            if let lyrics = lyrics {
                ScrollView {
                    VStack {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollViewOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(track.trackName)
                                .font(.largeTitle.weight(.bold))
                                .opacity(hasScrolledPastTitle ? 0 : 1)
                            if !genres.isEmpty {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 12) {
                                        ForEach(genres, id: \.musicGenreId) { genre in
                                            Text(genre.musicGenreName)
                                                .font(.system(size: 16))
                                                .padding(12)
                                                .background(Material.thin)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.horizontal, -16)
                            }
                        }
                        Divider()
                            .padding(.horizontal, -16)
                            .padding(.vertical, 12)
                        Text(lyrics.lyrics_body)
                    }
                    .padding([.bottom, .horizontal])
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        DispatchQueue.main.async {
                            self.offset = value.first ?? 0
                            
                            withAnimation(.easeInOut(duration: 0.22)) {
                                if offset <= 90 {
                                    hasScrolledPastTitle = true
                                } else {
                                    hasScrolledPastTitle = false
                                }
                                if offset <= 145 {
                                    showDivider = true
                                } else {
                                    showDivider = false
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
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            musixmatchService.fetchLyrics(forTrackId: track.trackId) { lyrics in
                self.showDetailSheet = true
                self.lyrics = lyrics
            }
        }
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}
