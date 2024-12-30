//
//  ExploreView.swift
//  Lyrics
//
//  Created by Liam Willey on 6/26/24.
//

import SwiftUI

struct ExploreView: View {
    @State var searchText = ""
    
    @State var hasSearchedASong = false
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var isLoading: Bool {
        return musixmatchService.isLoadingPopularSongs || musixmatchService.isLoadingPopularArtists || musixmatchService.isLoadingSongs
    }
    
    @ObservedObject var musixmatchService = MusixmatchService.shared
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                CustomNavBar(title: NSLocalizedString("explore", comment: ""), collapsed: .constant(true), collapsedTitle: .constant(true))
                    .padding()
                Divider()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle()
                                .frame(width: geo.size.width * 0.60, height: geo.size.width * 0.60)
                                .offset(x: -50, y: 2-0)
                            Circle()
                                .frame(width: geo.size.width * 0.27, height: geo.size.width * 0.27)
                                .offset(x: 70, y: 35)
                        }
                        .blur(radius: 40)
                        .foregroundColor(.blue.opacity(0.65))
                        .padding()
                        .frame(height: 360)
                        .overlay {
                            VStack(spacing: 20) {
                                VStack(spacing: 14) {
                                    FAText(iconName: "music-magnifying-glass", size: 55)
                                    Text("search_and_add")
                                        .font(.largeTitle.weight(.bold))
                                        .multilineTextAlignment(.center)
                                }
                                HStack(spacing: 5) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("search", text: $searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .onSubmit {
                                            hasSearchedASong = true
                                            musixmatchService.searchForSongs(searchText)
                                        }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(Material.thin)
                                .clipShape(Capsule())
                                .frame(width: geo.size.width * 0.70)
                            }
                        }
                        if isLoading {
                            ProgressView("Loading")
                                .frame(maxWidth: .infinity)
                        } else {
                            if hasSearchedASong {
                                VStack {
                                    ForEach(musixmatchService.searchedSongs, id: \.trackId) { track in
                                        NavigationLink {
                                            SongExploreDetailView(track: track)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(track.trackName)
                                                        .font(.body.weight(.semibold))
                                                    Text(track.artistName)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(2)
                                                        .font(.system(size: 16))
                                                }
                                                .multilineTextAlignment(.leading)
                                                Spacer()
                                                Text("E")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(.lightGray))
                                                    .padding(3)
                                                    .background(Color.gray.opacity(0.3))
                                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                                    .opacity(track.explicit == 1 ? 1 : 0)
                                                Image(systemName: "chevron.right")
                                                    .font(.body.weight(.medium))
                                                    .foregroundColor(.gray)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Material.regular)
                                            .foregroundColor(.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                        }
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("popular_songs")
                                        .textCase(.uppercase)
                                        .font(.system(size: 14).weight(.bold))
                                    LazyVGrid(columns: columns, alignment: .leading) {
                                        ForEach(musixmatchService.popularSongs, id: \.trackId) { track in
                                            NavigationLink {
                                                SongExploreDetailView(track: track)
                                            } label: {
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        Text("E")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(Color(.lightGray))
                                                            .padding(3)
                                                            .background(Color.gray.opacity(0.3))
                                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                                            .opacity(track.explicit == 1 ? 1 : 0)
                                                        Spacer() // Don't use .frame because it causes odd scroll behavior
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(track.artistName)
                                                            .foregroundColor(.gray)
                                                            .lineLimit(2)
                                                            .font(.system(size: 16))
                                                        Text(track.trackName)
                                                            .font(.body.weight(.semibold))
                                                    }
                                                    .multilineTextAlignment(.leading)
                                                }
                                                .padding(13)
                                                .frame(height: 175)
                                                .background(Material.regular)
                                                .foregroundColor(.primary)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                            }
                                        }
                                    }
                                }
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("popular_artists")
                                        .textCase(.uppercase)
                                        .font(.system(size: 14).weight(.bold))
                                    LazyVGrid(columns: columns, alignment: .leading) {
                                        ForEach(musixmatchService.popularArtists, id: \.artist_id) { artist in
                                            HStack {
                                                Text(artist.artist_name)
                                                    .font(.body.weight(.semibold))
                                                    .lineLimit(3)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                            .padding(13)
                                            .frame(height: 70)
                                            .background(Material.regular)
                                            .foregroundColor(.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                        }
                                    }
                                }
                            }
                        }
                        if !isLoading {
                            Text("powered_by_musixmatch")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            musixmatchService.requestPopularSongs()
            musixmatchService.requestPopularArtists()
        }
    }
}

#Preview {
    ExploreView()
}
