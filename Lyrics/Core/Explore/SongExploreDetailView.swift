//
//  SongExploreDetailView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/27/24.
//

import SwiftUI

struct SongExploreDetailView: View {
    @ObservedObject var musixmatchService = MusixmatchService.shared
    
    @State var lyrics: Lyrics?
    
    let song: Track
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(title: song.trackName)
                .padding()
            Divider()
            if let lyrics = lyrics {
                ScrollView {
                    VStack {
                        Text(lyrics.lyrics_body)
                    }
                    .padding()
                }
            } else {
                ProgressView("Loading")
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            musixmatchService.fetchLyrics(forTrackId: song.trackId) { lyrics in
                self.lyrics = lyrics
            }
        }
    }
}
